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
  let(:data) { Y2ConfigurationManagement::Salt::FormData.new(form, pillar.data) }
  let(:path) { ".root.person.computers" }
  let(:popup) { instance_double(Y2ConfigurationManagement::Widgets::FormPopup, run: nil) }
  let(:widget) do
    instance_double(Y2ConfigurationManagement::Widgets::Form, result: result, "value=" => nil)
  end
  let(:result) { nil }

  before do
    allow(Y2ConfigurationManagement::Salt::FormData).to receive(:new)
      .and_return(data)
    allow(Y2ConfigurationManagement::Salt::FormBuilder).to receive(:new)
      .with(controller).and_return(builder)
    allow(Y2ConfigurationManagement::Widgets::FormPopup).to receive(:new).and_return(popup)
  end

  describe "#show_main_dialog" do
    it "opens the dialog with the whole form" do
      expect(builder).to receive(:build).with(form.root.elements).and_call_original
      expect(Yast::CWM).to receive(:show)
      controller.show_main_dialog
    end
  end

  describe "#add" do
    let(:prototype) { form.find_element_by(path: path).prototype }

    before do
      allow(Y2ConfigurationManagement::Widgets::FormPopup)
        .to receive(:new).and_return(popup)
      allow(builder).to receive(:build).and_call_original
      allow(builder).to receive(:build).with(prototype).and_return(widget)
    end

    it "opens the dialog using the collections's prototype" do
      expect(builder).to receive(:build).with(prototype).and_return(widget)
      controller.add(path)
    end

    context "when the user accepts the dialog" do
      let(:result) { { "computers" =>  { "brand" => "Lenovo", "disks" => 2 } } }

      it "updates the form data" do
        expect(data).to receive(:add_item).with(path, "brand" => "Lenovo", "disks" => 2)
        controller.add(path)
      end
    end

    context "when the user cancels the dialog" do
      let(:result) { nil }

      it "does not modify form data" do
        expect(data).to_not receive(:add_item)
        controller.add(path)
      end
    end
  end

  describe "#edit" do
    let(:result) { nil }
    let(:prototype) { form.find_element_by(path: path).prototype }

    before do
      allow(builder).to receive(:build).and_call_original
      allow(builder).to receive(:build).with(prototype).and_return(widget)
    end

    it "opens the dialog using the collections's prototype" do
      expect(builder).to receive(:build).with(prototype).and_return(widget)
      controller.edit(path, 0)
    end

    context "when the user accepts the dialog" do
      let(:result) { { "computers" =>  { "brand" => "Lenovo", "disks" => 2 } } }

      it "updates the form data" do
        expect(data).to receive(:update_item).with(path, 0, "brand" => "Lenovo", "disks" => 2)
        controller.edit(path, 0)
      end
    end

    context "when the user cancels the dialog" do
      let(:result) { nil }

      it "does not modify form data" do
        expect(data).to_not receive(:update_item)
        controller.edit(path, 0)
      end
    end
  end

  describe "#remove" do
    it "removes an element" do
      expect(data).to receive(:remove_item).with(".root.person.computers", 1)
      controller.remove(".root.person.computers", 1)
    end
  end
end
