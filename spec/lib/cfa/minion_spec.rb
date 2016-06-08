require_relative "../../spec_helper"
require "scm/cfa/minion"

describe Yast::SCM::CFA::Minion do
  subject(:config) { Yast::SCM::CFA::Minion.new }

  before do
    stub_const("Yast::SCM::CFA::Minion::PATH", "spec/fixtures/salt/minion")
    config.load
  end

  describe "#master" do
    it "returns master server name" do
      expect(config.master).to eq("salt")
    end
  end
end
