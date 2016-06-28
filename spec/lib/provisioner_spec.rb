require_relative "../spec_helper"
require "scm/provisioner"
require "scm/key_finder"
require "yast2/execute"

describe Yast::SCM::Provisioner do
  subject(:provisioner) { Yast::SCM::Provisioner.new(config) }

  let(:master) { "myserver" }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:keys_url) { nil }
  let(:file_from_url_wrapper) { Yast::SCM::FileFromUrlWrapper }

  let(:config) do
    { attempts: 3, timeout: 10, master: master, config_url: config_url, keys_url: keys_url }
  end

  describe "#master" do
    it "returns the master option" do
      expect(provisioner.master).to eq(config[:master])
    end
  end

  describe "#attempts" do
    it "returns the master option" do
      expect(provisioner.attempts).to eq(config[:attempts])
    end
  end

  describe "#timeout" do
    it "returns the timeout option" do
      expect(provisioner.timeout).to eq(config[:timeout])
    end
  end

  describe "#mode" do
    context "when a master was given" do
      it "returns :client" do
        expect(provisioner.mode).to eq(:client)
      end
    end

    context "when no master but configuration URL was given" do
      let(:master) { nil }

      it "returns :masterless" do
        expect(provisioner.mode).to eq(:masterless)
      end
    end

    context "when neither master nor configuration URL are given" do
      let(:master) { nil }
      let(:config_url) { nil }

      it "client mode is used as fallback" do
        expect(provisioner.mode).to eq(:client)
      end
    end
  end

  describe "#packages" do
    it "returns no packages to install/remove" do
      expect(provisioner.packages).to eq({})
    end
  end

  describe "#run" do
    context "when running in masterless mode" do
      let(:master) { nil }
      let(:fetched_config) { true }

      before do
        allow(provisioner).to receive(:fetch_config).and_return(fetched_config)
      end


      it "fetches the configuration" do
        allow(provisioner).to receive(:apply_masterless_mode).and_return(true)
        expect(provisioner).to receive(:fetch_config)
        provisioner.run
      end

      context "and fetching and applying the configuration succeeds" do
        before do
          allow(provisioner).to receive(:apply_masterless_mode).and_return(true)
          allow(provisioner).to receive(:fetch_config).and_return(true)
        end

        it "returns true" do
          expect(provisioner.run).to eq(true)
        end
      end

      context "and fetching the configuration fails" do
        let(:fetched_config) { false }

        it "returns false" do
          expect(provisioner.run).to eq(false)
        end
      end

      context "and applying the configuration fails" do
        before do
          allow(provisioner).to receive(:apply_masterless_mode).and_return(false)
        end

        it "returns false" do
          expect(provisioner.run).to eq(false)
        end
      end

      context "and apply_masterless_mode is not redefined" do
        it "raises NotImplementedError" do
          expect { provisioner.run }.to raise_error(NotImplementedError)
        end
      end
    end

    context "when running in client mode" do
      context "when #update_configuration is not defined" do
        it "raises NotImplementedError" do
          expect { provisioner.run }.to raise_error(NotImplementedError)
        end
      end

      context "when #apply_client_mode is not defined" do
        before do
          allow(provisioner).to receive(:update_configuration).and_return(true)
        end

        it "raises NotImplementedError" do
          expect { provisioner.run }.to raise_error(NotImplementedError)
        end
      end

      context "when applying the configuration fails" do
        before do
          allow(provisioner).to receive(:update_configuration).and_return(true)
          allow(provisioner).to receive(:apply_client_mode).and_return(false)
        end

        it "returns false" do
          expect(provisioner.run).to eq(false)
        end
      end

      context "when applying the configuration succeeds" do
        before do
          allow(provisioner).to receive(:update_configuration).and_return(true)
          allow(provisioner).to receive(:apply_client_mode).and_return(true)
        end

        it "returns true" do
          expect(provisioner.run).to eq(true)
        end
      end
    end

    describe "#fetch_keys" do
      let(:keys_url) { "https://yast.example.net/keys" }
      let(:key_finder) { double("key_finder") }
      let(:public_key_path) { Pathname("/tmp/public") }
      let(:private_key_path) { Pathname("/tmp/private") }

      before do
        allow(provisioner).to receive(:public_key_path)
          .and_return(Pathname("/tmp/public"))
        allow(provisioner).to receive(:private_key_path)
          .and_return(Pathname("/tmp/private"))
      end

      it "copy keys" do
        expect(Yast::SCM::KeyFinder).to receive(:new)
          .with(keys_url: URI(keys_url)).and_return(key_finder)
        expect(key_finder).to receive(:fetch_to)
          .with(private_key_path, public_key_path)
        provisioner.fetch_keys
      end
    end

    describe "#fetch_config" do
      let(:tmpdir) { Pathname("/tmp") }

      before do
        allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
      end

      it "downloads and uncompress the configuration to a temporal directory" do
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(URI(config_url), tmpdir.join(Yast::SCM::Provisioner::CONFIG_LOCAL_FILENAME))
          .and_return(true)
        expect(Yast::Execute).to receive(:locally).with("tar", "xf", *any_args)
          .and_return(true)

        provisioner.fetch_config
      end

      context "when the file is downloaded and uncompressed" do
        before do
          allow(file_from_url_wrapper).to receive(:get_file).and_return(true)
          allow(Yast::Execute).to receive(:locally).with("tar", *any_args).and_return(true)
        end

        it "returns true" do
          expect(provisioner.fetch_config).to eq(true)
        end
      end

      context "when download fails" do
        before do
          allow(provisioner).to receive(:get_file_from_url).and_return(false)
        end

        it "returns false" do
          expect(provisioner.fetch_config).to eq(false)
        end
      end

      context "when uncompressing fails" do
        before do
          allow(provisioner).to receive(:get_file_from_url).and_return(true)
          allow(Yast::Execute).to receive(:locally).with("tar", *any_args).and_raise(Cheetah::ExecutionFailed)
        end

        it "returns false" do
          expect(provisioner.fetch_config).to eq(false)
        end
      end
    end
  end
end
