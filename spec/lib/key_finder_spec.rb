require_relative "../spec_helper"
require "scm/key_finder"
require "pathname"

describe Yast::SCM::KeyFinder do
  Yast.import "Hostname"

  let(:hostname) { "minion" }
  let(:keys_url) { URI("http://keys.example.net/salt") }
  let(:file_from_url_wrapper) { Yast::SCM::FileFromUrlWrapper }

  subject(:finder) { Yast::SCM::KeyFinder.new(keys_url: keys_url) }

  before do
    allow(Yast::Hostname).to receive(:CurrentFQ).and_return(hostname)
  end

  describe "#fetch_to" do
    let(:target_key) { Pathname("/etc/salt/pki/minion/minion.key") }
    let(:target_pub) { Pathname("/etc/salt/pki/minion/minion.pub") }

    context "when a key named after the ID is found" do
      subject(:finder) do
        Yast::SCM::KeyFinder.new(keys_url: keys_url, id: "someid")
      end

      it "copies the key and returns true" do
        key_url = URI("#{keys_url}/someid.key")
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(key_url, target_key)
          .and_return(true)

        pub_url = URI("#{keys_url}/someid.pub")
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(pub_url, target_pub)
          .and_return(true)

        expect(finder.fetch_to(target_key, target_pub)).to eq(true)
      end
    end

    context "when a key named after the hostname is found" do
      subject(:finder) do
        Yast::SCM::KeyFinder.new(keys_url: keys_url, id: "someid")
      end

      before do
        allow(file_from_url_wrapper).to receive(:get_file)
          .once.and_return(false)
      end

      it "copies the key and returns true" do
        key_url = URI("#{keys_url}/someid.key")
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(key_url, target_key)
          .and_return(true)

        pub_url = URI("#{keys_url}/someid.pub")
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(pub_url, target_pub)
          .and_return(true)

        expect(finder.fetch_to(target_key, target_pub)).to eq(true)
      end
    end

    context "when no key is found" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file)
          .and_return(false)
      end

      it "returns false" do
        expect(finder.fetch_to(target_key, target_pub)).to eq(false)
      end
    end
  end
end
