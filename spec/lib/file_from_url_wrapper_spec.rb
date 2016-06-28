require_relative "../spec_helper"
require "scm/file_from_url_wrapper"
require "uri"
require "pathname"

describe Yast::SCM::FileFromUrlWrapper do
  describe "#get_file" do
    described_class { Yast::SCM::FileFromUrlWrapper }
    subject(:wrapper) { described_class }

    let(:uri) { URI("http://yast.example.net/some-file.txt") }
    let(:target) { Pathname("/tmp/local-file.txt")}

    it "decompose URI and calls original get_file_from_url" do
      expect(wrapper).to receive(:get_file_from_url).with(
        scheme: "http", host: "yast.example.net",
        urlpath: "/some-file.txt", urltok: {}, destdir: "/",
        localfile: "/tmp/local-file.txt")
      wrapper.get_file(uri, target)
    end

    it "returns value from get_file_from_url" do
      allow(Yast::SCM::FileFromUrlWrapper).to receive(:get_file_from_url)
        .and_return("some-value")
      expect(Yast::SCM::FileFromUrlWrapper.get_file(uri, target))
        .to eq("some-value")
    end
  end
end
