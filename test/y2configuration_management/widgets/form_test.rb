#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
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
require "y2configuration_management/widgets/form"
require "y2configuration_management/widgets/text"

describe Y2ConfigurationManagement::Widgets::Form do
  subject(:form) { described_class.new(widget, double("controller")) }

  let(:widget) do
    instance_double(
      Y2ConfigurationManagement::Widgets::Text, id: "text1", value: "foobar", :value= => nil,
      :parent= => nil
    )
  end
  let(:new_val) { { "text1" => "example" } }

  describe "#init" do
    before { form.value = new_val }

    it "sets values for underlying widgets" do
      expect(widget).to receive(:value=).with("example")
      form.init
    end
  end

  describe "#refresh" do
    it "sets values for underlying widgets" do
      expect(widget).to receive(:value=).with("example")
      form.refresh(new_val)
    end

    it "sets the widget's value" do
      expect { form.refresh(new_val) }.to change { form.value }.to(new_val)
    end

    it "resets the widget's result" do
      form.store
      expect { form.refresh(new_val) }.to change { form.result }.from(Hash).to(nil)
    end
  end

  describe "#store" do
    it "stores the final result" do
      expect { form.store }.to change { form.result }.from(nil).to("text1" => "foobar")
    end
  end

  describe "#result" do
    before { form.store }

    it "returns an hash including the values" do
      expect(form.result).to eq("text1" => "foobar")
    end

    context "when using an scalar form" do
      subject(:form) { described_class.new(widget, double("controller"), scalar: true) }

      it "returns a hash with a single '$value' key" do
        expect(form.result).to eq("$value" => "foobar")
      end
    end
  end
end
