#!/usr/bin/env rspec

require_relative "../spec_helper"
require "configuration_management/file_from_url_wrapper"
require "uri"
require "pathname"

describe Yast::ConfigurationManagement::FileFromUrlWrapper do
  describe "#get_file" do
    described_class { Yast::ConfigurationManagement::FileFromUrlWrapper }
    subject(:wrapper) { described_class }

    let(:uri_port) { URI("http://yast.example.net:8888/some-file.txt") }
    let(:uri) { URI("http://yast.example.net/some-file.txt") }
    let(:usb) { URI("usb:///some-file.txt") }
    let(:target) { Pathname("/tmp/local-file.txt") }

    it "decompose URI (with port) and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "http", host: "yast.example.net",
        urlpath: "/some-file.txt",
        urltok: {"scheme"=>"http", "path"=>"/some-file.txt", "query"=>"",
          "fragment"=>"", "user"=>"", "pass"=>"", "port"=>"8888",
          "host"=>"yast.example.net"},
        destdir: "/", localfile: "/tmp/local-file.txt"
      )
      wrapper.get_file(uri_port, target)
    end

    it "decompose URI (without port) and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "http", host: "yast.example.net",
        urlpath: "/some-file.txt",
        urltok: {"scheme"=>"http", "path"=>"/some-file.txt", "query"=>"",
          "fragment"=>"", "user"=>"", "pass"=>"", "port"=>"",
          "host"=>"yast.example.net"},
        destdir: "/", localfile: "/tmp/local-file.txt"
      )
      wrapper.get_file(uri, target)
    end

    it "decompose USB URI and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "usb", host: "",
        urlpath: "/some-file.txt",
        urltok: {"scheme"=>"usb", "path"=>"", "query"=>"", "fragment"=>"",
          "user"=>"", "pass"=>"", "port"=>"", "host"=>"some-file.txt"},
        destdir: "/", localfile: "/tmp/local-file.txt"
      )
      wrapper.get_file(usb, target)
    end

    it "returns value from get_file_from_url" do
      allow(Yast::ConfigurationManagement::FileFromUrlWrapper).to receive(:get_file_from_url)
        .and_return("some-value")
      expect(Yast::ConfigurationManagement::FileFromUrlWrapper.get_file(uri, target))
        .to eq("some-value")
    end
  end
end
