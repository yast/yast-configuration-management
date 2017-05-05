#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/configurations/base"
require "tmpdir"

describe Yast::ConfigurationManagement::Configurations::Base do
  subject(:config) { Yast::ConfigurationManagement::Configurations::Base.new(profile) }

  let(:master) { "some-server.suse.com" }
  let(:auth_attempts) { 3 }
  let(:default_path) { FIXTURES_PATH.join("cm-salt.yml") }

  let(:profile) do
    {
      "type"          => "salt",
      "master"        => master,
      "auth_attempts" => 5,
      "auth_time_out" => 10,
      "keys_url"      => "http://internal-server.com/keys.tgz"
    }
  end

  before do
    stub_const("Yast::ConfigurationManagement::Configurations::Base::DEFAULT_PATH", default_path)
  end

  context "default configuration" do
    subject(:config) { Yast::ConfigurationManagement::Configurations::Base.new({}) }

    let(:attrs) do
      {
        auth_attempts: 3,
        auth_time_out: 15,
        type:          nil,
        mode:          :masterless,
        keys_url:      nil
      }
    end

    it { is_expected.to have_attributes(attrs) }
  end

  describe "#mode" do
    context "when a master server is not specified" do
      let(:master) { nil }

      it "returns :masterless" do
        expect(config.mode).to eq(:masterless)
      end
    end

    context "when a master server is specified" do
      it "returns :client" do
        expect(config.mode).to eq(:client)
      end
    end
  end

  describe "#work_dir" do
    let(:now) { Time.new(2017, 5, 4, 15, 0) }
    let(:expected) { "#{Yast::Directory.vardir}/cm-201705041500"}

    before do
      allow(Time).to receive(:now).and_return(now)
      allow(Yast::Installation).to receive(:destdir).and_return("/mnt")
      allow(Yast::Directory).to receive(:vardir).and_return("/var/lib/YaST")
    end

    context "when no scope is given" do
      it "returns a path with a timestamp prefixed by the installation directory" do
        expect(config.work_dir).to eq(Pathname("/mnt#{expected}"))
      end
    end

    context "when :local scope is given" do
      it "returns a path with a timestamp prefixed by the installation directory" do
        expect(config.work_dir(:local)).to eq(Pathname("/mnt#{expected}"))
      end
    end

    context "when no scope is given" do
      it "returns a path with a timestamp not prefixed by the installation directory" do
        expect(config.work_dir(:target)).to eq(Pathname(expected))
      end
    end
  end
end
