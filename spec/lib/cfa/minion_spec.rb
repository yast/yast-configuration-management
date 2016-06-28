require_relative "../../spec_helper"
require "cm/cfa/minion"

describe Yast::CM::CFA::Minion do
  subject(:config) { Yast::CM::CFA::Minion.new }

  before do
    stub_const("Yast::CM::CFA::Minion::PATH", "spec/fixtures/salt/minion")
    config.load
  end

  describe "#master" do
    it "returns master server name" do
      expect(config.master).to eq("salt")
    end
  end
end
