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
require "y2configuration_management/widgets/color"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Color do
  subject(:color) { described_class.new(spec, locator) }
  let(:form_spec) { { "bg_color" => { "$type" => "color", "$default" => default } } }
  let(:form) { Y2ConfigurationManagement::Salt::Form.new(form_spec) }
  let(:spec) { form.find_element_by(locator: locator) }
  let(:locator) { locator_from_string("root#bg_color") }
  let(:default) { "#02D35F" }

  include_examples "CWM::AbstractWidget"

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      color = described_class.new(spec, locator)
      expect(color.locator).to eq(locator)
    end
  end

  describe "#validate" do
    let(:value) { "" }

    before do
      allow(color).to receive(:value).and_return(value)
    end

    context "when the value is empty" do
      it "returns true" do
        expect(color.validate).to eql(true)
      end
    end

    context "when the current value is a valid HEX color" do
      let(:value) { default }

      it "returns true" do
        expect(color.validate).to eql(true)
      end
    end

    context "when the current value is not a valid HEX color" do
      let(:value) { "#ahrdfH" }

      it "returns false" do
        expect(color.validate).to eql(false)
      end
    end
  end
end
