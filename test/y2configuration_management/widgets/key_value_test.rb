#!/usr/bin/env rspec
# Copyright (c) [2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../spec_helper"
require "y2configuration_management/widgets/key_value"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::KeyValue do
  let(:form) { Y2ConfigurationManagement::Salt::Form.new(form_spec) }
  let(:form_spec) do
    {
      "servers" => {
        "$type"      => "edit-group",
        "$prototype" => {
          "$type" => "text",
          "$key"  => { "$type" => "$text" }
        }
      }
    }
  end
  let(:spec) { form.find_element_by(locator: locator) }
  let(:locator) { locator_from_string("root#servers") }
  let(:key_widget) { dictionary.send(:key_widget) }
  let(:value_widget) { dictionary.send(:value_widget) }
  subject(:dictionary) { described_class.new(spec, locator) }
  include_examples "CWM::CustomWidget"

  describe "#contents" do
    it "contains a InputFIeld for the $key and $value" do
      key_input = subject.contents.nested_find { |i| i.label == subject.label }
      value_input = subject.contents.nested_find { |i| i.label == _("Value") }

      expect(key_input).to_not eql(nil)
      expect(value_input).to_not eql(nil)
    end
  end

  describe "#value=" do
    let(:value) { { "$key" => "example.com", "$value" => "1.2.3.4" } }

    it "fills the $key input properly" do
      expect(key_widget).to receive(:value=).with("example.com")
      subject.value = value
    end

    it "fills the $value input properly" do
      expect(value_widget).to receive(:value=).with("1.2.3.4")
      subject.value = value
    end

    it "caches the value" do
      subject.value = value
      expect(subject).to receive(:value=).with(value)
      subject.init
    end

    context "when nil or an empty array is given" do
      it "resets the value of the $value and $key widgets" do
        expect(key_widget).to receive(:value=).with(nil)
        expect(value_widget).to receive(:value=).with(nil)
        subject.value = {}
      end
    end
  end

  describe "#value" do
    let(:key_widget_value) { "YaST" }
    let(:value_widget_value) { "team" }

    before do
      allow(key_widget).to receive(:value).and_return(key_widget_value)
    end

    context "when the $key input is empty" do
      let(:key_widget_value) { "" }

      it "returns an empty hash" do
        expect(subject.value).to be_a(Hash)
        expect(subject.value).to be_empty
      end
    end

    context "when the $key input is not empty" do
      it "returns a hash with $key and $value keys" do
        expect(subject.value).to be_a(Hash)
        expect(subject.value.keys).to eql(["$key", "$value"])
      end
    end
  end

  describe "#validate" do
    let(:key_widget_value) { "YaST" }
    let(:value_widget_value) { "Team" }

    before do
      allow(key_widget).to receive(:value).and_return(key_widget_value)
    end

    context "when the $key input is empty" do
      let(:key_widget_value) { "" }

      it "returns false" do
        expect(subject.validate).to eql(false)
      end
    end

    context "when the $key input is not empty" do
      it "returns true" do
        expect(subject.validate).to eql(true)
      end
    end
  end
end
