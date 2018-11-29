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
require "y2configuration_management/salt/form_controller"
require "y2configuration_management/salt/form"
require "y2configuration_management/widgets"

describe Y2ConfigurationManagement::Salt::FormBuilder do
  subject(:builder) { described_class.new(controller) }
  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:element) { form.find_element_by(path: path) }
  let(:controller) { instance_double(Y2ConfigurationManagement::Salt::FormController) }

  describe "#build" do
    context "when an input form element is given" do
      let(:path) { ".root.person.name" }

      it "returns an array containing a text widget" do
        widgets = builder.build(element)
        expect(widgets).to be_all(Y2ConfigurationManagement::Widgets::Text)
        expect(widgets).to contain_exactly(
          an_object_having_attributes(
            "path" => ".root.person.name"
          )
        )
      end
    end

    context "when a group form element is given" do
      let(:path) { ".root.person.address" }

      it "returns an array containing a group widgets" do
        widgets = builder.build(element)
        group = widgets.first
        expect(group.children).to contain_exactly(
          an_object_having_attributes("path" => ".root.person.address.street"),
          an_object_having_attributes("path" => ".root.person.address.country")
        )
      end
    end

    context "when a collection is given" do
      let(:path) { ".root.person.computers" }

      it "returns an array containing a collection widget" do
        widgets = builder.build(element)
        expect(widgets).to be_all(Y2ConfigurationManagement::Widgets::Collection)
      end
    end
  end
end
