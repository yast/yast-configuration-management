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
require "y2configuration_management/salt/form_controller_state"
require "y2configuration_management/salt/form_data"
require "y2configuration_management/salt/form_element_locator"
require "y2configuration_management/widgets/form"

describe Y2ConfigurationManagement::Salt::FormControllerState do
  subject(:state) { described_class.new(data) }
  let(:form_widget) { instance_double(Y2ConfigurationManagement::Widgets::Form) }
  let(:locator) { instance_double(Y2ConfigurationManagement::Salt::FormElementLocator) }
  let(:form_widget_1) { instance_double(Y2ConfigurationManagement::Widgets::Form) }
  let(:locator_1) { instance_double(Y2ConfigurationManagement::Salt::FormElementLocator) }
  let(:data) { instance_double(Y2ConfigurationManagement::Salt::FormData) }

  describe "#open_form" do
    it "sets action, locator and element" do
      state.open_form(:add, locator, form_widget)
      expect(state.action).to eq(:add)
      expect(state.form_widget).to eq(form_widget)
      expect(state.locator).to eq(locator)
    end

    context "when a form is already open" do
      before do
        state.open_form(:add, locator, form_widget)
      end

      it "adds the information of the new form" do
        state.open_form(:edit, locator_1, form_widget_1)
        expect(state.action).to eq(:edit)
        expect(state.locator).to eq(locator_1)
        expect(state.form_widget).to eq(form_widget_1)
      end
    end
  end

  describe "#close_form" do
    before do
      state.open_form(:add, locator, form_widget)
      state.open_form(:edit, locator_1, form_widget_1)
    end

    it "removes the information of the most recent form" do
      state.close_form
      expect(state.action).to eq(:add)
    end
  end

  describe "#form_data" do
    it "returns the form data" do
      expect(state.form_data).to eq(data)
    end
  end
end
