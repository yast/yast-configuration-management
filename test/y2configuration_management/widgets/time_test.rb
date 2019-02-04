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
require "y2configuration_management/widgets/time"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Time do
  subject(:time) { described_class.new(spec) }
  let(:form_spec) { { "start_time" => { "$type" => "time" } } }
  let(:form) { Y2ConfigurationManagement::Salt::Form.new(form_spec) }

  let(:spec) { form.find_element_by(locator: locator) }
  let(:locator) { locator_from_string("root#start_time") }

  include_examples "CWM::TimeField"

  describe "#init" do
    it "returns if there is no default value" do
      expect(time).to_not receive(:value=)
      time.init
    end

    context "when the time field has already a cached value" do
      let(:form_spec) { { "start_time" => { "$type" => "time", "$default" => "10:00:00" } } }

      before do
        time.instance_variable_set("@value", "15:00:00")
      end

      it "inits the widget value with the cached one" do
        expect(time).to receive(:value=).with("15:00:00")
        time.init
      end
    end

    context "when the datetime does not have a cached value" do
      let(:form_spec) { { "start_time" => { "$type" => "time", "$default" => "10:00:00" } } }

      it "inits the widget value with the default one" do
        expect(time).to receive(:value=).with("10:00:00")
        time.init
      end
    end
  end

  describe "#value=" do
    it "caches the given value" do
      value = "17:30:00"
      expect(time.instance_variable_get("@value")).to_not eql(value)
      time.value = value
      expect(time.instance_variable_get("@value")).to eql(value)
    end
  end
end
