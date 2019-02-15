#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/salt/form"

describe Y2ConfigurationManagement::Salt::Form do
  subject(:form) { described_class.from_file(form_path) }

  let(:formula_path) { FIXTURES_PATH.join("formulas").join("test-formula") }
  let(:form_path) { FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml") }

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
      expect(form.find_element_by(locator: locator_from_string("root#person#name")))
        .to be_a(Y2ConfigurationManagement::Salt::FormInput)

      number = form.find_element_by(name: "E-mail")
      expect(number).to be_a(Y2ConfigurationManagement::Salt::FormInput)
      expect(number.locator.to_s).to eql("root#person#email")
      expect(form.find_element_by(id: "root"))
        .to be_a(Y2ConfigurationManagement::Salt::Container)

      nested = form.find_element_by(
        locator: locator_from_string("root#person#computers#disks#size")
      )
      expect(nested).to be_a(Y2ConfigurationManagement::Salt::FormInput)
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
    let(:file_path) { FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml") }
    let(:locator_form) { Y2ConfigurationManagement::Salt::Form.from_file(file_path) }

    it "returns the absolute form element locator in the Form" do
      computers_collection = locator_form.find_element_by(id: "computers")
      expect(computers_collection.locator.to_s).to eql("root#person#computers")
      brand = computers_collection.prototype.find_element_by(id: "brand")
      expect(brand.locator.to_s).to eql("root#person#computers#brand")
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

  describe "#collection_key?" do
    subject(:form_element) { form.find_element_by(locator: locator) }
    let(:form) do
      Y2ConfigurationManagement::Salt::Form.from_file(
        FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
      )
    end

    context "when the element is named '$key'" do
      let(:locator) { locator_from_string("root#person#projects#\$key") }

      it "returns true" do
        expect(form_element.collection_key?).to eq(true)
      end
    end

    context "when the element is named different from '$key'" do
      let(:locator) { locator_from_string("root#person#projects#url") }

      it "returns false" do
        expect(form_element.collection_key?).to eq(false)
      end
    end
  end

  describe "#default_data" do
    subject(:form_element) { form.find_element_by(locator: locator) }
    let(:locator) { locator_from_string("root#person") }
    let(:form) do
      Y2ConfigurationManagement::Salt::Form.from_file(
        FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
      )
    end

    it "returns form data containing default values from included elements" do
      defaults = form_element.default_data
      expect(defaults).to be_a(Y2ConfigurationManagement::Salt::FormData)
      expect(defaults.value)
        .to include("address" => { "country" => "Czech Republic", "street" => nil })
    end
  end
end

describe Y2ConfigurationManagement::Salt::Collection do
  subject(:collection) { form.find_element_by(locator: locator) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(
      FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
    )
  end

  include_examples "Y2ConfigurationManagement::Salt::FormElement"

  describe "#find_element_by" do
    let(:locator) { locator_from_string("root#person#projects") }

    context "when the locator matches its own locator" do
      it "returns itself" do
        expect(collection).to be_a(described_class)
      end
    end

    context "when the locator matches some prototype element" do
      it "returns the element from the protoype" do
        element = collection.find_element_by(locator: locator.join(:url))
        expect(element).to be_a(Y2ConfigurationManagement::Salt::FormInput)
      end
    end
  end

  describe "#keyed?" do
    context "when it is a collection indexed by a key" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "returns true" do
        expect(collection).to be_keyed
      end
    end

    context "when it is a collection indexed by an index" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns false" do
        expect(collection).to_not be_keyed
      end
    end
  end

  describe "#simple_scalar?" do
    context "when an scalar collection is given" do
      let(:locator) { locator_from_string("root#person#projects#platforms") }

      it "returns true" do
        expect(collection).to be_simple_scalar
      end
    end

    context "when another kind of collection is given" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns false" do
        expect(collection).to_not be_simple_scalar
      end
    end
  end

  describe "#keyed_scalar?" do
    context "when a hash based collection with scalar values is given" do
      let(:locator) { locator_from_string("root#person#projects#properties") }

      it "returns true" do
        expect(collection).to be_keyed_scalar
      end
    end

    context "when another kind of collection is given" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns false" do
        expect(collection).to_not be_keyed_scalar
      end
    end
  end

  describe "#default_data" do
    let(:locator) { locator_from_string("root#person#projects#platforms") }

    it "returns the form data containing the default values" do
      default = collection.default_data
      expect(default).to be_a(Y2ConfigurationManagement::Salt::FormData)
      expect(default.value).to eq([{ "$value" => "Linux" }])
    end
  end

  describe "#prototype_default_data" do
    context "given an array based collection" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns the form data containing the default values for the prototype" do
        default = collection.prototype_default_data
        expect(default.value).to eq(
          "brand" => "Dell", "disks" => []
        )
      end
    end

    context "given a hash based collection" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "returns the form data containing the default values for the prototype" do
        default = collection.prototype_default_data
        expect(default.value).to include(
          "$key" => nil, "url" => "https://github.com/yast"
        )
      end
    end

    context "given a key-value scalar collection" do
      let(:locator) { locator_from_string("root#person#projects#properties") }

      it "returns the form data containing the default values for the prototype" do
        default = collection.prototype_default_data
        expect(default.value).to eq("$key" => "key1", "$value" => "value1")
      end
    end

    context "given a simple scalar collection" do
      let(:locator) { locator_from_string("root#person#projects#platforms") }

      it "returns the form data containing the default values for the prototype" do
        default = collection.prototype_default_data
        expect(default.value).to eq("$value" => "Platform")
      end
    end
  end
end
