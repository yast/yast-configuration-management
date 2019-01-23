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
require "y2configuration_management/widgets/email"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Email do
  subject(:email) { described_class.new(spec) }

  include_examples "CWM::AbstractWidget"

  let(:form_spec) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:spec) { form_spec.find_element_by(locator: locator) }
  let(:locator) { locator_from_string(".root.person.email") }
  let(:default) { "somebody@example.net" }

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      email = described_class.new(spec)
      expect(email.locator).to eq(locator)
      expect(email.default).to eq(default)
    end
  end

  describe "#init" do
    it "initializes the current value to the default one" do
      expect(email).to receive(:value=).with(default)
      email.init
    end

    context "when no default value was given" do
      let(:spec) do
        sp = form_spec.find_element_by(locator: locator)
        sp.instance_variable_set(:@default, nil)
        sp
      end

      it "initializes the current value to the empty string" do
        expect(email).to receive(:value=).with("")
        email.init
      end
    end
  end

  describe "#validate" do
    let(:value) { default }
    before do
      allow(email).to receive(:value).and_return(value)
    end

    context "when the introduced email is not valid" do
      let(:value) { "1nvalid_email" }

      it "reports an error" do
        expect(Yast::Report).to receive(:Error)
        email.validate
      end

      it "returns false" do
        expect(email.validate).to eql(false)
      end
    end

    context "when the introduced email is valid" do
      it "returns true" do
        expect(email.validate).to eql(true)
      end
    end
  end
end
