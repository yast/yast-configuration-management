#!/usr/bin/env rspec

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

  describe "#auth_retries" do
    it "returns auth_tries value" do
      expect(config.auth_tries).to eq(7)
    end
  end

  describe "#auth_retries=" do
    it "sets auth_tries value" do
      config.auth_tries = 3
      expect(config.auth_tries).to eq(3)
    end

    it "unsets auth_tries value if nil is specified" do
      config.auth_tries = nil
      expect(config.auth_tries).to be_nil
    end

    it "converts the value to a Fixnum" do
      config.auth_tries = "5"
      expect(config.auth_tries).to eq(5)
    end
  end

  describe "#auth_timeout" do
    it "returns auth_timeout value" do
      expect(config.auth_timeout).to eq(60)
    end
  end

  describe "#auth_timeout=" do
    it "sets auth_timeout value" do
      config.auth_timeout = 30
      expect(config.auth_timeout).to eq(30)
    end

    it "unsets auth_timeout value if nil is specified" do
      config.auth_timeout = nil
      expect(config.auth_timeout).to be_nil
    end

    it "converts the value to a Fixnum" do
      config.auth_timeout = "5"
      expect(config.auth_timeout).to eq(5)
    end
  end

  describe "#update" do
    it "sets the given values" do
      attrs = { master: "some-master", auth_tries: 5, auth_timeout: 30 }
      config.update(attrs)
      expect({master: config.master, auth_tries: config.auth_tries, auth_timeout: config.auth_timeout})
        .to eq(attrs)
    end

    it "does not modify not specified values" do
      expect { config.update(auth_tries: 1) }.to_not change { config.auth_timeout }
    end
  end
end
