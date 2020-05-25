#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/configurations/base"
require "tmpdir"

describe Y2ConfigurationManagement::Configurations::Base do
  subject(:config) { Y2ConfigurationManagement::Configurations::Base.new(profile) }

  let(:master) { "some-server.suse.com" }
  let(:auth_attempts) { 3 }
  let(:default_path) { FIXTURES_PATH.join("cm-salt.yml") }

  let(:profile) do
    {
      type:          "salt",
      master:        master,
      auth_attempts: 5,
      auth_time_out: 10,
      keys_url:      "http://internal-server.com/keys.tgz"
    }
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

    before do
      allow(Time).to receive(:now).and_return(now)
      allow(Yast::Directory).to receive(:vardir).and_return("/var/lib/YaST")
    end

    it "returns a path including a timestamp under YaST's var directory" do
      expect(config.work_dir.to_s).to eq(File.join(Yast::Directory.vardir, "cm-201705041500"))
    end
  end
end
