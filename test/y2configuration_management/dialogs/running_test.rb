require_relative "../../spec_helper"
require "y2configuration_management/dialogs/running"

describe Y2ConfigurationManagement::Dialogs::Running do
  Yast.import "UI"
  include Yast::UIShortcuts

  subject(:dialog) { described_class.new(reporting_opts: reporting_opts) }
  let(:reporting_opts) { { open_after_success: false, open_after_error: false } }

  describe "#run" do
    let(:block) { ->(o, _e) { o } }

    before do
      allow(Yast::UI).to receive(:UserInput).and_return(:ok)
      allow(Yast::UI).to receive(:QueryWidget)
        .with(Id(:progress), :Value).and_return("")
      allow(Yast::UI).to receive(:ChangeWidget)
    end

    it "runs the given block" do
      expect(block).to receive(:call).and_call_original
      dialog.run(&block)
    end

    context "when block writes to the output channel" do
      let(:block) { ->(o, _e) { o << "out" } }
      it "displays blocks' stdout in real-time" do
        expect(Yast::UI).to receive(:ChangeWidget)
          .with(Id(:progress), :Value, "out")
        dialog.run(&block)
      end
    end

    context "when block writes to the error channel" do
      let(:block) { ->(_o, e) { e << "err" } }

      it "displays blocks' stderr in real-time" do
        expect(Yast::UI).to receive(:ChangeWidget)
          .with(Id(:progress), :Value, "err")
        dialog.run(&block)
      end
    end

    context "when some content was displayed" do
      let(:block) { ->(o, _e) { o << "second\nthird" } }

      before do
        allow(Yast::UI).to receive(:QueryWidget)
          .with(Id(:progress), :Value).and_return("first")
      end

      it "adds the new content replacing '\n' por '<br>'" do
        expect(Yast::UI).to receive(:ChangeWidget)
          .with(Id(:progress), :Value, "first<br>second<br>third")
        dialog.run(&block)
      end
    end

    context "when it runs successfully" do
      let(:block) { -> (_o, _e) { true } }
      let(:reporting_opts) { { open_after_success: true, timeout_after_success: 10 } }

      context "and a timeout was set" do
        it "waits until the timeout ends" do
          expect(Yast::UI).to receive(:TimeoutUserInput).exactly(10).times
            .and_return(:timeout)
          dialog.run(&block)
        end
      end

      context "and no timeout was set" do
        let(:reporting_opts) { { open_after_success: true, timeout_after_success: nil } }

        it "waits until the user presses 'OK'" do
          expect(Yast::UI).to_not receive(:TimeoutUserInput)
          expect(Yast::UI).to receive(:UserInput).and_return(:ok)
          dialog.run(&block)
        end
      end

      context "and it should no stop on success" do
        let(:reporting_opts) { { open_after_success: false } }

        it "does not stop" do
          expect(dialog).to_not receive(:event_loop)
          expect(dialog.run(&block)).to eq(:ok)
        end
      end
    end

    context "when an error happens" do
      let(:block) { -> (_o, _e) { false } }
      let(:reporting_opts) { { open_after_error: true, timeout_after_error: 5 } }

      context "and a timeout was set" do
        it "waits until the timeout ends" do
          expect(Yast::UI).to receive(:TimeoutUserInput).exactly(5).times
            .and_return(:timeout)
          dialog.run(&block)
        end
      end

      context "and no timeout was set" do
        let(:reporting_opts) { { open_after_error: true, timeout_after_error: nil } }

        it "waits until the user presses 'OK'" do
          expect(Yast::UI).to_not receive(:TimeoutUserInput)
          expect(Yast::UI).to receive(:UserInput).and_return(:ok)
          dialog.run(&block)
        end
      end

      context "and it should no stop on error" do
        let(:reporting_opts) { { open_after_error: false } }

        it "does not stop" do
          expect(dialog).to_not receive(:event_loop)
          expect(dialog.run(&block)).to eq(:ok)
        end
      end
    end
  end
end
