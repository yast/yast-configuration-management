#!/usr/bin/env rspec
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
require "y2configuration_management/widgets/collection"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/form_controller"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Collection do
  subject(:collection) { described_class.new(spec, controller) }

  include_examples "CWM::CustomWidget"

  let(:form_spec) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:spec) { form_spec.find_element_by(path: path) }
  let(:path) { ".root.person.computers" }
  let(:controller) { instance_double(Y2ConfigurationManagement::Salt::FormController) }

  describe ".new" do
    it "instantiates a new widget according to the spec" do
      collection = described_class.new(spec, controller)
      expect(collection.path).to eq(path)
      expect(collection.min_items).to eq(1)
      expect(collection.max_items).to eq(4)
    end
  end

  describe "#handle" do
    context "when it is an 'add' event" do
      let(:event) { { "ID" => "#{collection.widget_id}_add".to_sym } }

      it "adds a new element to the collection" do
        expect(controller).to receive(:add).with(path)
        collection.handle(event)
      end
    end

    context "when it is an 'edit' event" do
      let(:event) { { "ID" => "#{collection.widget_id}_edit".to_sym } }

      before do
        allow(collection).to receive(:selected_row).and_return(1)
      end

      it "edits an element of the collection" do
        expect(controller).to receive(:edit).with(path, 1)
        collection.handle(event)
      end
    end

    context "when it is a 'remove' event" do
      let(:event) { { "ID" => "#{collection.widget_id}_remove".to_sym } }

      before do
        allow(collection).to receive(:selected_row).and_return(1)
      end

      it "removes the selected element from the collection" do
        expect(controller).to receive(:remove).with(path, 1)
        collection.handle(event)
      end
    end
  end

  describe "#headers" do
    it "returns the headers to be displayed in the table" do
      expect(collection.headers).to eq(["Brand", "Number of Disks"])
    end
  end

  shared_examples "collection" do
    describe ".new" do
      it "instantiates a new widget according to the spec" do
        collection = described_class.new(spec, controller)
        expect(collection.path).to eq(path)
      end
    end
  end

  context "for a collection of scalars, without $default" do
    let(:form_spec) do
      Y2ConfigurationManagement::Salt::Form.new(
        "person" => {
          "$type" => "namespace",
          "computers" => {
            "$type" => "edit-group",
            "$prototype" => { "$type" => "text" }
          }
        }
      )
    end

    include_examples "collection"
  end
end
