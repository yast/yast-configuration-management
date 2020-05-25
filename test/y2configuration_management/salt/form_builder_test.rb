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
  subject(:builder) { described_class.new(controller, form) }
  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(
      FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
    )
  end
  let(:element) { form.find_element_by(locator: locator) }
  let(:controller) { instance_double(Y2ConfigurationManagement::Salt::FormController) }

  describe "#build" do
    context "when a locator of an input form element is given" do
      let(:locator) { locator_from_string("root#person#name") }

      it "returns a form containing a text widget" do
        form_widget = builder.build(locator)
        widget = form_widget.widget
        expect(widget).to be_a(Y2ConfigurationManagement::Widgets::Text)
        expect(widget.locator).to eq(locator_from_string("root#person#name"))
      end

      it "returns a single value form" do
        form_widget = builder.build(locator)
        expect(form_widget).to be_a(Y2ConfigurationManagement::Widgets::SingleValueForm)
      end
    end

    context "when a locator of a group form element is given" do
      let(:locator) { locator_from_string("root#person#address") }

      it "returns a form containing group widgets" do
        form_widget = builder.build(locator)
        expect(form_widget.widgets.map(&:relative_locator)).to contain_exactly(
          locator_from_string("#street"),
          locator_from_string("#country")
        )
      end
    end

    context "when a locator of a collection is given" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns a form containing a collection widget" do
        form_widget = builder.build(locator)
        expect(form_widget.widgets).to contain_exactly(
          an_object_having_attributes(
            "relative_locator" => locator_from_string("brand")
          ),
          an_object_having_attributes(
            "relative_locator" => locator_from_string("disks")
          )
        )
      end
    end

    context "when the locator of the root element is given" do
      let(:locator) { locator_from_string("root") }

      it "returns a form including the containers but excluding 'root'" do
        form_widget = builder.build(locator)
        person = form_widget.tree_pager.items.first
        expect(person.id).to eq("page:person")
        expect(person.children.values.map(&:id))
          .to eq(["page:newsletter", "page:address", "page:computers", "page:projects"])
      end
    end

    context "when the locator of a container element is given" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns a form including the container" do
        form_widget = builder.build(locator)
        computers = form_widget.tree_pager.items.first
        expect(computers.page.children).to contain_exactly(
          an_object_having_attributes("relative_locator" => locator_from_string("brand"))
        )
        expect(computers.children.values.map(&:id)).to eq(["page:disks"])
      end
    end

    it "places form elements which type is 'namespace' in separated pages" do
      form_widget = builder.build(locator_from_string("root#person"))
      person = form_widget.tree_pager.items.first
      expect(person.page.children.map(&:id)).to_not include("newsletter")
    end
  end
end
