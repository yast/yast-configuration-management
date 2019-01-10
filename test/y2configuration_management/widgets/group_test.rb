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
require "y2configuration_management/widgets/text"
require "y2configuration_management/widgets/group"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Group do
  subject(:group) { described_class.new(spec, [widget1]) }

  include_examples "CWM::CustomWidget"

  let(:form_spec) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:spec) { form_spec.find_element_by(locator: locator) }
  let(:locator) { locator_from_string(".root.person.address") }
  let(:widget1) { instance_double(Y2ConfigurationManagement::Widgets::Text, id: "widget1") }

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      group = described_class.new(spec, [widget1])
      expect(group.locator).to eq(locator)
    end
  end

  describe "#value=" do
    it "sets values of underlying widgets" do
      expect(widget1).to receive(:value=).with("foobar")
      group.value = { "widget1" => "foobar" }
    end
  end
end
