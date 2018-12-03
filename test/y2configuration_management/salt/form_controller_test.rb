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
    it "opens the dialog using the collections's prototype"
  end

  describe "#remove" do
    it "removes an element" do
      expect(data).to receive(:remove).with(".root.person.computers", 1)
      controller.remove(".root.person.computers", 1)
    end
  end
end
