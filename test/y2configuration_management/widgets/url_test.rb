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
require "y2configuration_management/widgets/url"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::URL do
  subject(:url) { described_class.new(spec, locator) }

  include_examples "CWM::AbstractWidget"

  let(:form_spec) do
    Y2ConfigurationManagement::Salt::Form.from_file(
      FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
    )
  end
  let(:spec) { form_spec.find_element_by(locator: locator) }
  let(:locator) { locator_from_string("root#person#homepage") }
  let(:default) { "http://myhomepage.com" }

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      expect(url.locator).to eq(locator)
    end
  end

  describe "#validate" do
    let(:value) { default }
    before do
      allow(url).to receive(:value).and_return(value)
    end

    context "when the introduced URL is not valid" do
      let(:value) { "http:||" }

      it "reports an error" do
        expect(Yast::Report).to receive(:Error)
        url.validate
      end

      it "returns false" do
        allow(Yast::Report).to receive(:Error)
        expect(url.validate).to eql(false)
      end
    end

    context "when the introduced URL is valid" do
      it "returns true" do
        expect(url.validate).to eql(true)
      end
    end
  end
end
