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
require "y2configuration_management/salt/form_controller"

describe Y2ConfigurationManagement::Salt::FormController do
  subject(:controller) { described_class.new(form) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end

  let(:builder) { Y2ConfigurationManagement::Salt::FormBuilder.new(controller) }
  let(:data) { Y2ConfigurationManagement::Salt::FormData.new(form) }

  before do
    allow(Y2ConfigurationManagement::Salt::FormData).to receive(:new)
      .and_return(data)
    allow(Y2ConfigurationManagement::Salt::FormBuilder).to receive(:new)
      .with(controller).and_return(builder)
  end

  describe "#show_main_dialog" do
    it "opens the dialog with the whole form" do
      expect(builder).to receive(:build).with(form.root.elements).and_call_original
      expect(Yast::CWM).to receive(:show)
      controller.show_main_dialog
    end
  end

  describe "#add" do
    let(:path) { ".root.person.computers" }
    let(:popup) { instance_double(Y2ConfigurationManagement::Widgets::FormPopup, run: nil) }
    let(:widget) { instance_double(Y2ConfigurationManagement::Widgets::Form, result: result) }
    let(:result) { nil }
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
        controller.add(path)
        expect(data.get(".root.person.computers")).to include("brand" => "Lenovo", "disks" => 2)
      end
    end

    context "when the user cancels the dialog" do
      let(:result) { nil }

      it "does not modify form data" do
        expect(data).to_not receive(:add)
        controller.add(path)
      end
    end
  end

  describe "#remove" do
    it "removes an element" do
      expect(data).to receive(:remove).with(".root.person.computers", 1)
      controller.remove(".root.person.computers", 1)
    end
  end
end
