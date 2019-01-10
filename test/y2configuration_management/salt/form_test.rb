#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/salt/form"

describe Y2ConfigurationManagement::Salt::Form do
  subject { described_class.new(formula_path.to_s) }
  let(:formula_path) { FIXTURES_PATH.join("formulas").join("test-formula") }
  let(:form_path) { formula_path.join("form.yml") }
  let(:form) { described_class.from_file(form_path) }

  describe ".from_file" do
    it "reads the form specification from a YAML file" do
      expect(form).to be_a(described_class)
    end
  end

  describe ".new" do
    let(:spec) { { "test" => { "$type" => "text" } } }
    let(:form) { described_class.new(spec) }

    it "creates a new #{described_class} instance from the given specification" do
      expect(form).to be_a(described_class)
    end

    it "creates a root container where the rest of elements descend from" do
      expect(form.root).to be_a(Y2ConfigurationManagement::Salt::Container)
    end
  end

  describe "#root" do
    it "returns the form root Y2ConfigurationManagement::Salt::Container" do
      expect(form.root).to be_a(Y2ConfigurationManagement::Salt::Container)
      expect(form.root.name).to eql("Root")
    end
  end

  describe "#find_element_by" do
    it "returns the FormElment which match a given argument" do
      expect(form.find_element_by(locator: locator_from_string(".root.demo.system.text")))
        .to be_a(Y2ConfigurationManagement::Salt::FormInput)

      number = form.find_element_by(name: "Number")
      expect(number).to be_a(Y2ConfigurationManagement::Salt::FormInput)
      expect(number.locator.to_s).to eql(".root.demo.number")
      expect(form.find_element_by(id: "root"))
        .to be_a(Y2ConfigurationManagement::Salt::Container)
    end

    it "returns nil if no FormElement match the given attribute" do
      expect(form.find_element_by(name: "ghost")).to be_nil
    end
  end
end

shared_examples "Y2ConfigurationManagement::Salt::FormElement" do
  let(:id) { "test" }
  let(:spec) { { id => { "$type" => "text", "$name" => "My Element" } } }

  let(:form_element) { described_class.new(id, spec, parent: nil) }

  describe ".new" do
    it "creates a new #{described_class} instance from the given specification" do
      expect(form_element).to be_a(described_class)
    end

    context "when a name is not given in the specification" do
      let(:spec) { { id => { "$type" => "text" } } }

      it "uses the humanized 'id' as the default 'label'" do
        expect(form_element.label).to eql("Test")
      end

      context "when the id contains dashes and/or underscores" do
        let(:id) { "suse--fancy_salt_test" }

        it "capitalizes words" do
          expect(form_element.name).to eql("Suse Fancy Salt Test")
        end
      end
    end

    context "when a 'scope' is not given in the specification" do
      let(:spec) { { id => { "$type" => "text" } } }

      it "uses :system as the default 'scope'" do
        expect(form_element.scope).to eql(:system)
      end
    end
  end
end

describe Y2ConfigurationManagement::Salt::FormElement do
  include_examples "Y2ConfigurationManagement::Salt::FormElement"

  describe "#locator" do
    let(:file_path) { FIXTURES_PATH.join("form.yml") }
    let(:locator_form) { Y2ConfigurationManagement::Salt::Form.from_file(file_path) }

    it "returns the absolute form element locator in the Form" do
      computers_collection = locator_form.find_element_by(id: "computers")
      expect(computers_collection.locator.to_s).to eql(".root.person.computers")
      brand = computers_collection.prototype.find_element_by(id: "brand")
      expect(brand.locator.to_s).to eql(".root.person.computers.computers.brand")
    end
  end
end

describe Y2ConfigurationManagement::Salt::FormInput do
  include_examples "Y2ConfigurationManagement::Salt::FormElement"
end

describe Y2ConfigurationManagement::Salt::Container do
  include_examples "Y2ConfigurationManagement::Salt::FormElement"

  subject { described_class.new(formula_path.to_s) }
  let(:formula_path) { FIXTURES_PATH.join("formulas").join("test-formula") }
  let(:form_path) { formula_path.join("form.yml") }
  let(:form) { Y2ConfigurationManagement::Salt::Form.from_file(form_path) }

  describe "#elements" do
    it "returns the list of FormElements that are part of the container" do
      container = form.root
      expect(container.elements.size).to eql(1)
      expect(container.elements[0]).to be_a(Y2ConfigurationManagement::Salt::Container)
      expect(container.elements[0].id).to eql("demo")
    end
  end
end

describe Y2ConfigurationManagement::Salt::Collection do
  include_examples "Y2ConfigurationManagement::Salt::FormElement"
end
