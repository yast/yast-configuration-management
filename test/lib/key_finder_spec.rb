#!/usr/bin/env rspec

require_relative "../spec_helper"
require "cm/key_finder"
require "pathname"
require "fileutils"

describe Yast::CM::KeyFinder do
  Yast.import "Hostname"

  let(:hostname) { "minion" }
  let(:keys_url) { URI("http://keys.example.net/salt") }
  let(:file_from_url_wrapper) { Yast::CM::FileFromUrlWrapper }

  subject(:finder) { Yast::CM::KeyFinder.new(keys_url: keys_url) }

  before do
    allow(Yast::Hostname).to receive(:CurrentFQ).and_return(hostname)
  end

  describe "#fetch_to" do
    let(:target_key) { Pathname("/etc/salt/pki/minion/minion.key") }
    let(:target_pub) { Pathname("/etc/salt/pki/minion/minion.pub") }

    before do
      allow(::FileUtils).to receive(:chmod)
    end

    context "when keys were retrieved" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file)
          .and_return(true)
      end

      it "returns true" do
        expect(finder.fetch_to(target_key, target_pub)).to eq(true)

      end
    end

    context "when a pair of keys named after the ID is found" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file).and_return(true)
      end

      subject(:finder) do
        Yast::CM::KeyFinder.new(keys_url: keys_url, id: "someid")
      end

      it "copies the pair of keys 'someid'" do
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(URI("#{keys_url}/someid.key"), target_key)
          .and_return(true)
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(URI("#{keys_url}/someid.pub"), target_pub)
          .and_return(true)
        finder.fetch_to(target_key, target_pub)
      end

      it "sets permissions on copied keys" do
        expect(FileUtils).to receive(:chmod).with(0o644, target_pub)
        expect(FileUtils).to receive(:chmod).with(0o400, target_key)
        finder.fetch_to(target_key, target_pub)
      end
    end

    context "when a pair of keys named after the hostname is found" do
      subject(:finder) do
        Yast::CM::KeyFinder.new(keys_url: keys_url, id: "someid")
      end

      before do
        allow(file_from_url_wrapper).to receive(:get_file)
          .twice.and_return(false)
      end

      it "copies the pair of keys for that hostname" do
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(URI("#{keys_url}/#{hostname}.key"), target_key)
          .and_return(true)
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(URI("#{keys_url}/#{hostname}.pub"), target_pub)
          .and_return(true)
        finder.fetch_to(target_key, target_pub)
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

    context "when downloading the public key fails" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file)
          .with(anything, target_key).and_return(true)
        allow(file_from_url_wrapper).to receive(:get_file)
          .with(anything, target_pub).and_return(false)
        allow(target_key).to receive(:exist?).and_return(true)
      end

      it "returns false" do
        allow(FileUtils).to receive(:rm).with(target_key)
        expect(finder.fetch_to(target_key, target_pub)).to eq(false)
      end

      it "cleans up the private key" do
        expect(FileUtils).to receive(:rm).with(target_key).at_least(1)
        finder.fetch_to(target_key, target_pub)
      end
    end
  end
end
