#!/usr/bin/env rspec

require_relative "../../spec_helper"

require "cm/salt/formula"

describe Yast::CM::Salt::Formula do
  FORMULAS_PATH = FIXTURES_PATH.join("formulas")

  subject { described_class.new(formula_path.to_s) }
  let(:formula_path) { FORMULAS_PATH.join("test-formula") }

  describe ".all" do
    it "returns all the formulas in a given directory" do
      formulas = described_class.all(FORMULAS_PATH.to_s)
      expect(formulas).to be_kind_of(Array)
      expect(formulas.first.name).to eq("test-formula")
    end
  end

  describe "#form_for_group" do
    context "when the group exists" do
      it "retrieves the sub form data for a given form group path" do
        expect(subject.form_for_group(".demo.group"))
          .to eq("$type" => "group", "$scope" => "group", "text" =>
            { "$default" => "text" }, "checkbox" => { "$type" => "boolean" })
      end
    end

    context "when the group does not exist" do
      it "returns nil" do
        expect(subject.form_for_group(".demo.not_exist.other")).to eq(nil)
      end
    end
  end

  describe "#default_values" do
    it "returns default values from formula" do
      values = subject.default_values
      expect(values["demo"]).to include("text" => "some text")
      expect(values["demo"]["group"]).to include("text" => "text")
    end
  end

  describe "#values_for_group=" do
    it "sets values for a group" do
      expect { subject.set_values_for_group(".demo.group", "text" => "hello!") }
        .to change { subject.values_for_group(".demo.group") }
        .from("text" => "text").to("text" => "hello!")
    end
  end

  describe "#values_for_group" do
    it "returns values for a given group" do
      expect(subject.values_for_group(".demo.group"))
        .to eq("text" => "text")
    end

    context "when group has a subgroup" do
      it "returns values for a given group" do
        expect(subject.values_for_group(".demo.system"))
          .to eq("text" => "text")
      end
    end
  end
end
