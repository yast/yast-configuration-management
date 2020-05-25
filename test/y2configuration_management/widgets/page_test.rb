#!/usr/bin/env rspec
# encoding: utf-8

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
require "y2configuration_management/widgets/page"
require "y2configuration_management/widgets/text"
require "y2configuration_management/salt/form_data"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Page do
  subject(:page) do
    described_class.new("foo", "Foo", widgets).tap { |p| p.tree_item = tree_item }
  end
  let(:widgets) { [widget1, widget2] }
  let(:widget1) do
    instance_double(
      Y2ConfigurationManagement::Widgets::Text, id: "name", value: "Jane",
      min_height: 1
    ).as_null_object
  end

  let(:widget2) do
    instance_double(
      Y2ConfigurationManagement::Widgets::Text, id: "surname", value: "Doe",
      min_height: 2
    ).as_null_object
  end

  let(:tree_item) { double("tree_item", pager: pager) }
  let(:pager) { double("pager") }

  include_examples "CWM::Page"

  describe "#store" do
    before do
      allow(pager).to receive(:current_page).and_return(current_page)
    end

    context "when the page is visible" do
      let(:current_page) { page }

      it "stores the values from the widgets" do
        page.store
        expect(page.value).to eq("name" => "Jane", "surname" => "Doe")
      end
    end

    context "when the page is not visible" do
      let(:current_page) { double("page").as_null_object }

      it "does not store the values from the widgets" do
        page.store
        expect(page.value).to be_nil
      end
    end
  end

  describe "#min_height" do
    it "returns sum of the min_height of the underlying widgets" do
      expect(page.min_height).to eq(3)
    end
  end

  describe "#update_visibility" do
    let(:data) { Y2ConfigurationManagement::Salt::FormData.new({}) }

    it "updates children visibility" do
      expect(widget1).to receive(:update_visibility).with(data)
      expect(widget2).to receive(:update_visibility).with(data)
      page.update_visibility(data)
    end
  end
end
