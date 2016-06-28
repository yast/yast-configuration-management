require_relative "../spec_helper"
require "scm/key_finder"

describe Yast::SCM::KeyFinder do
  Yast.import "Hostname"
  let(:hostname) { "minion" }
  let(:base_url) { URI("http://keys.example.net/salt") }

  subject(:finder) { Yast::SCM::KeyFinder.new(base_url: base_url) }

  before do
    allow(Yast::Hostname).to receive(:CurrentFQ).and_return(hostname)
  end

  describe "#fetch_to" do
    let(:target) { "/etc/salt/pki/minion/minion" }
    let(:get_file_from_url_params) do
      {
        scheme: base_url.scheme, host: base_url.host, urltok: {},
        destdir: "/", localfile: target
      }
    end

    context "when a key named after the ID is found" do
      subject(:finder) do
        Yast::SCM::KeyFinder.new(base_url: base_url, id: "someid")
      end

      it "copies the key and returns true" do
        expect(finder).to receive(:get_file_from_url)
          .with(get_file_from_url_params
            .merge(localfile: "#{target}.key", urlpath: "/salt/someid.key"))
          .and_return(true)

        expect(finder).to receive(:get_file_from_url)
          .with(get_file_from_url_params
            .merge(localfile: "#{target}.pub", urlpath: "/salt/someid.pub"))
          .and_return(true)

        expect(finder.fetch_to("#{target}.key", "#{target}.pub"))
          .to eq(true)
      end
    end

    context "when a key named after the hostname is found" do
      subject(:finder) do
        Yast::SCM::KeyFinder.new(base_url: base_url, id: "someid")
      end

      before do
        allow(finder).to receive(:get_file_from_url).once.and_return(false)
      end

      it "copies the key and returns true" do
        expect(finder).to receive(:get_file_from_url)
          .with(get_file_from_url_params
            .merge(localfile: "#{target}.key", urlpath: "/salt/minion.key"))
          .and_return(true)

        expect(finder).to receive(:get_file_from_url)
          .with(get_file_from_url_params
            .merge(localfile: "#{target}.pub", urlpath: "/salt/minion.pub"))
          .and_return(true)

        expect(finder.fetch_to("#{target}.key", "#{target}.pub"))
          .to eq(true)
      end
    end

    context "when no key is found" do
      before do
        allow(finder).to receive(:get_file_from_url).and_return(false)
      end

      it "returns false" do
        expect(finder.fetch_to("#{target}.key", "#{target}.pub"))
          .to eq(false)
      end
    end
  end
end
