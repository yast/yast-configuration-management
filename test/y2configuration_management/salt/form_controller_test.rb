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
require "y2configuration_management/salt/form_builder"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/pillar"
require "y2configuration_management/salt/form_controller"

describe Y2ConfigurationManagement::Salt::FormController do
  subject(:controller) { described_class.new(form, pillar) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:pillar_path) { FIXTURES_PATH.join("pillar/test-formula.sls") }
  let(:pillar) { Y2ConfigurationManagement::Salt::Pillar.from_file(pillar_path) }

  let(:builder) { Y2ConfigurationManagement::Salt::FormBuilder.new(controller) }
  let(:data) { Y2ConfigurationManagement::Salt::FormData.from_pillar(form, pillar) }
  let(:locator) { locator_from_string(".root.person.computers") }
  let(:collection_locator) { locator_from_string(".person.computers") }
  let(:popup) { instance_double(Y2ConfigurationManagement::Widgets::FormPopup, run: popup_run) }
  let(:popup_run) { :ok }
  let(:widget) do
    instance_double(Y2ConfigurationManagement::Widgets::Form, result: result).as_null_object
  end
  let(:result) { nil }
  let(:state) { Y2ConfigurationManagement::Salt::FormControllerState.new(data) }

  before do
    allow(Y2ConfigurationManagement::Salt::FormControllerState).to receive(:new)
      .and_return(state)
    allow(Y2ConfigurationManagement::Salt::FormBuilder).to receive(:new)
      .with(controller).and_return(builder)
    allow(Y2ConfigurationManagement::Widgets::FormPopup).to receive(:new).and_return(popup)
    state.open_form(:edit, form.root.locator, builder.build(form.root))
  end

  shared_examples "form_controller" do
    describe "#show_main_dialog" do
      let(:event_id) { :next }

      before do
        # Instead of mocking CWM.show we let the CWM preparation a step further,
        # to catch bugs in widget initialization
        allow(Yast::UI).to receive(:WaitForEvent).and_return("ID" => event_id)
      end

      it "opens the dialog with the whole form" do
        expect(builder).to receive(:build).with(form.root).and_call_original
        expect(Yast::CWM).to receive(:show)
        controller.show_main_dialog
      end

      it "runs the dialog with the whole form" do
        expect(builder).to receive(:build).with(form.root).and_call_original
        controller.show_main_dialog
      end

      context "when the user accepts the dialog" do
        let(:event_id) { :next }

        it "returns :next" do
          expect(controller.show_main_dialog).to eq(:next)
        end
      end

      context "when the user cancels the form" do
        let(:event_id) { :abort }

        it "returns :abort" do
          expect(controller.show_main_dialog).to eq(:abort)
        end
      end
    end
  end

  include_examples "form_controller"

  describe "#add" do
    let(:prototype) { form.find_element_by(locator: locator).prototype }

    before do
      allow(Y2ConfigurationManagement::Widgets::FormPopup)
        .to receive(:new).and_return(popup)
      allow(builder).to receive(:build).and_call_original
      allow(builder).to receive(:build).with(prototype).and_return(widget)
    end

    it "opens the dialog using the collections's prototype" do
      expect(builder).to receive(:build).with(prototype).and_return(widget)
      controller.add(collection_locator)
    end

    context "when the user accepts the dialog" do
      let(:result) { { "brand" => "Lenovo", "disks" => [] } }

      it "updates the form data" do
        controller.add(collection_locator)
        expect(controller.get(locator)).to eq([result])
      end
    end

    context "when the user cancels the dialog" do
      let(:result) { nil }
      let(:popup_run) { :cancel }

      it "does not modify form data" do
        expect(data).to_not receive(:add_item)
        controller.add(collection_locator)
      end
    end

    context "adding an element to a nested collection" do
      let(:parent_form) do
        instance_double(
          Y2ConfigurationManagement::Widgets::Form, result: { "brand" => "Lenovo", "disks" => [] }
        ).as_null_object
      end

      before do
        allow(builder).to receive(:build).and_return(widget)
        allow(data).to receive(:add_item).and_call_original
        state.open_form(:add, locator_from_string(".root.person.computers"), parent_form)
      end

      context "when the user accepts the dialog" do
        let(:collection_locator) { locator_from_string(".disks") }
        let(:result) { { "type" => "HDD", "size" => "1TiB" } }

        it "updates the form data" do
          controller.add(collection_locator)
          collection = controller.get(locator_from_string(".root.person.computers[2].disks"))
          expect(collection).to eq([result])
        end
      end
    end
  end

  describe "#edit" do
    let(:result) { nil }
    let(:prototype) { form.find_element_by(locator: locator).prototype }

    before do
      allow(builder).to receive(:build).and_call_original
      allow(builder).to receive(:build).with(prototype).and_return(widget)
      allow(data).to receive(:update).and_call_original
    end

    it "opens the dialog using the collections's prototype" do
      expect(builder).to receive(:build).with(prototype).and_return(widget)
      controller.edit(collection_locator.join(0))
    end

    context "when the user accepts the dialog" do
      let(:result) { { "brand" => "Lenovo", "disks" => [] } }

      it "updates the form data" do
        controller.edit(collection_locator.join(0))
        expect(controller.get(locator.join(0))).to include(result)
      end
    end

    context "when the user cancels the dialog" do
      let(:result) { { "brand" => "Lenovo", "disks" => [] } }
      let(:popup_run) { :cancel }

      it "does not modify form data" do
        expect(data).to_not receive(:update).with(locator, anything)
        controller.edit(collection_locator.join(0))
      end
    end

    context "updating an element from a nested collection" do
      let(:parent_form) do
        instance_double(
          Y2ConfigurationManagement::Widgets::Form, result: { "brand" => "Lenovo", "disks" => [] }
        ).as_null_object
      end

      before do
        allow(builder).to receive(:build).and_return(widget)
        allow(data).to receive(:update).and_call_original
        state.open_form(:edit, locator_from_string(".root.person.computers[1]"), parent_form)
      end

      context "when the user accepts the dialog" do
        let(:collection_locator) { locator_from_string(".disks") }
        let(:result) { { "type" => "HDD", "size" => "1TiB" } }
        let(:disks_locator) { locator_from_string(".root.person.computers[1].disks") }

        it "updates the form data" do
          controller.add(collection_locator)
          expect(controller.get(disks_locator)).to include(result)
        end
      end
    end
  end

  describe "#remove" do
    let(:element_locator) { locator_from_string(".person.computers[1]") }

    it "removes an element" do
      expect { controller.remove(element_locator) }
        .to change { controller.get(locator_from_string(".root.person.computers[1]")) }
        .from(Hash)
        .to(nil)
    end
  end

  context "for a collection of scalars, without $default" do
    let(:form) do
      fname = FIXTURES_PATH.join("scalar-collection.yml")
      Y2ConfigurationManagement::Salt::Form.from_file(fname)
    end

    include_examples "form_controller"
  end
end
