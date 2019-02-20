#!/usr/bin/env rspec
# encoding: utf-8

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
require "y2configuration_management/widgets/single_value_form"
require "y2configuration_management/widgets/text"

describe Y2ConfigurationManagement::Widgets::SingleValueForm do
  subject(:form) { described_class.new(widget, title: "title1") }

  let(:widget) do
    instance_double(
      Y2ConfigurationManagement::Widgets::Text, id: "text1", value: "foobar"
    ).as_null_object
  end
  let(:new_val) { { "$value" => "example" } }

  describe "#init" do
    before { form.value = new_val }

    it "sets the widget's value" do
      expect(widget).to receive(:value=).with("example")
      form.init
    end
  end

  describe "#title" do
    it "returns the form's title" do
      expect(form.title).to eq("title1")
    end
  end

  describe "#result" do
    before { form.store }

    it "returns a hash including the widget's value" do
      expect(form.result).to eq("$value" => "foobar")
    end

    context "when using a widget with a complex value" do
      let(:widget) { double("key_value_widget", value: { "foo" => "bar" }).as_null_object }
      
      it "returns the widget's value" do
        expect(form.result).to eq("foo" => "bar")
      end
    end
  end
end
