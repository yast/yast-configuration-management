#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/configurations/salt"
require "y2configuration_management/configurators/salt"

describe Y2ConfigurationManagement::Configurators::Salt do
  subject(:configurator) { Y2ConfigurationManagement::Configurators::Salt.new(config) }

  let(:master) { "myserver" }
  let(:states_url) { "https://yast.example.net/mystates.tgz" }
  let(:pillar_url) { "https://yast.example.net/mypillar.tgz" }
  let(:tmpdir) { "/mnt/var/tmp/workdir" }
  let(:keys_url) { "https://yast.example.net/keys" }

  let(:config) do
    Y2ConfigurationManagement::Configurations::Salt.new(
      auth_attempts: 3,
      auth_time_out: 10,
      master:        master,
      states_url:    states_url,
      pillar_url:    pillar_url,
      keys_url:      keys_url
    )
  end

  before do
    allow(Yast::Installation).to receive(:destdir).and_return("/mnt")
    allow(FileUtils).to receive(:mkdir_p).with(config.work_dir)
  end

  describe "#packages" do
    context "when running in client mode" do
      it "returns a list containing 'salt' and 'salt-minion' packages" do
        expect(configurator.packages).to eq("install" => ["salt", "salt-minion"])
      end
    end

    context "when running in masterless mode" do
      let(:master) { nil }

      it "returns a list containing only the 'salt' package" do
        expect(configurator.packages).to eq("install" => ["salt"])
      end
    end
  end

  describe "#prepare" do
    context "when running in client mode" do
      let(:minion_config) { double("minion", load: true, save: true, exist?: false) }
      let(:key_finder) { double("key_finder", fetch_to: true) }

      before do
        allow(Y2ConfigurationManagement::CFA::Minion).to receive(:new).and_return(minion_config)
        allow(minion_config).to receive(:master=)
        allow(Y2ConfigurationManagement::KeyFinder).to receive(:new).and_return(key_finder)
        allow(FileUtils).to receive(:mkdir_p)
      end

      it "updates the configuration file" do
        expect(minion_config).to receive(:master=).with(master)
        configurator.prepare
      end

      it "retrieves authentication keys" do
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/mnt/etc/salt/pki/minion/minion.pem"),
            Pathname("/mnt/etc/salt/pki/minion/minion.pub"))
        configurator.prepare
      end
    end

    context "when running in masterless" do
      let(:master) { nil }
      let(:minion_config) { double("minion", load: true, save: true, exist?: false) }
      let(:key_finder) { double("key_finder", fetch_to: true) }
      let(:formula_sequence) do
        instance_double(Y2ConfigurationManagement::Salt::FormulaSequence, run: true)
      end

      before do
        allow(Y2ConfigurationManagement::CFA::Minion)
          .to receive(:new).and_return(minion_config)
        allow(minion_config).to receive(:set_file_roots)
        allow(configurator).to receive(:fetch_config)
        allow(Yast::WFM).to receive(:CallFunction)
        allow(Y2ConfigurationManagement::Salt::FormulaSequence).to receive(:new)
          .and_return(formula_sequence)
      end

      it "retrieves the Salt states" do
        expect(configurator).to receive(:fetch_config)
          .with(URI(states_url), config.work_dir(:local))
        expect(configurator).to receive(:fetch_config)
          .with(URI(pillar_url), config.work_dir(:local).join("pillar"))
        configurator.prepare
      end

      it "runs the configuration_management_formula client" do
        expect(Y2ConfigurationManagement::Salt::FormulaSequence).to receive(:new)
          .with(config, reverse: false).and_return(formula_sequence)
        configurator.prepare
      end

      it "sets file_roots in the minion's configuration" do
        expect(minion_config).to receive(:set_file_roots)
          .with([config.states_root(:target), config.formulas_root(:target)])
        configurator.prepare
      end
    end
  end
end
