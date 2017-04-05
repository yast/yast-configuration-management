require_relative "../../spec_helper"
require "configuration_management/dialogs/running"

describe Yast::ConfigurationManagement::Dialogs::Running do
  Yast.import "UI"
  include Yast::UIShortcuts

  subject(:dialog) { described_class.new }

  describe "#run" do
    let(:block) { ->(o, _e) { o } }

    before do
      allow(Yast::UI).to receive(:TimeoutUserInput).and_return(:ok)
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
  end
end
