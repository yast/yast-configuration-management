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
require "y2configuration_management/widgets/password"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Password do
  subject(:password) { described_class.new(spec) }

  include_examples "CWM::AbstractWidget"

  let(:form_spec) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end

  let(:spec) { form_spec.find_element_by(locator: locator) }
  let(:locator) { locator_from_string(".root.person.password") }

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      password = described_class.new(spec)
      expect(password.locator).to eq(locator)
      expect(password.default).to eq("DefaultSecret")
    end
  end

  describe "#init" do
    it "initializes the current value to the default one" do
      expect(password).to receive(:value=).with("DefaultSecret")
      password.init
    end

    context "when no default value was given" do
      let(:spec) do
        sp = form_spec.find_element_by(locator: locator)
        sp.instance_variable_set(:@default, nil)
        sp
      end

      it "initializes the current value to the empty string" do
        expect(password).to receive(:value=).with("")
        password.init
      end
    end
  end
end
