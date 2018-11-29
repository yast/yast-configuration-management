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
require "y2configuration_management/salt/form_controller"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Group do
  subject(:group) { described_class.new(spec, [widget1], controller) }

  include_examples "CWM::CustomWidget"

  let(:form_spec) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:spec) { form_spec.find_element_by(path: path) }
  let(:path) { ".root.person.address" }
  let(:controller) { instance_double(Y2ConfigurationManagement::Salt::FormController) }
  let(:widget1) { instance_double(Y2ConfigurationManagement::Widgets::Text) }

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      group = described_class.new(spec, [widget1], controller)
      expect(group.path).to eq(path)
    end
  end
end
