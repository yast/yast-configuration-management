#!/usr/bin/env rspec

require_relative "../spec_helper"
require "y2configuration_management/file_from_url_wrapper"
require "uri"
require "pathname"

describe Y2ConfigurationManagement::FileFromUrlWrapper do
  describe "#get_file" do
    described_class { Y2ConfigurationManagement::FileFromUrlWrapper }
    subject(:wrapper) { described_class }

    let(:uri_port) { URI("http://yast.example.net:8888/some-file.txt") }
    let(:uri) { URI("http://yast.example.net/some-file.txt") }
    let(:usb) { URI("usb:///some-file.txt") }
    let(:target) { Pathname("/tmp/local-file.txt") }

    it "decomposes URI (with port) and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "http", host: "yast.example.net",
        urlpath: "/some-file.txt",
        urltok: { "scheme" => "http", "path" => "/some-file.txt", "query" => "",
          "fragment" => "", "user" => "", "pass" => "", "port" => "8888",
          "host" => "yast.example.net" },
        destdir: "/", localfile: "/tmp/local-file.txt"
      )
      wrapper.get_file(uri_port, target)
    end

    it "decomposes URI (without port) and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "http", host: "yast.example.net",
        urlpath: "/some-file.txt",
        urltok: { "scheme" => "http", "path" => "/some-file.txt", "query" => "",
          "fragment" => "", "user" => "", "pass" => "", "port" => "",
          "host" => "yast.example.net" },
        destdir: "/", localfile: "/tmp/local-file.txt"
      )
      wrapper.get_file(uri, target)
    end

    it "decomposes USB URI and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "usb", host: "",
        urlpath: "/some-file.txt",
        urltok: Hash,
        destdir: "/", localfile: "/tmp/local-file.txt"
      )
      wrapper.get_file(usb, target)
    end

    it "returns value from get_file_from_url" do
      allow(Y2ConfigurationManagement::FileFromUrlWrapper).to receive(:get_file_from_url)
        .and_return("some-value")
      expect(Y2ConfigurationManagement::FileFromUrlWrapper.get_file(uri, target))
        .to eq("some-value")
    end
  end
end
