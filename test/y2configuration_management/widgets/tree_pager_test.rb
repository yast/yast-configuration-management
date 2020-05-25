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
require "y2configuration_management/widgets/tree_pager"
require "y2configuration_management/widgets/pager_tree_item"
require "y2configuration_management/salt/form_data"

describe Y2ConfigurationManagement::Widgets::TreePager do
  subject(:tree_pager) do
    described_class.new([item, sibling_item])
  end

  let(:item) do
    instance_double(
      Y2ConfigurationManagement::Widgets::PagerTreeItem, main: false, page_id: "data",
      value: EXAMPLE_VALUE["data"]
    ).as_null_object
  end

  let(:sibling_item) do
    instance_double(
      Y2ConfigurationManagement::Widgets::PagerTreeItem, main: false, page_id: "platforms",
      value: EXAMPLE_VALUE["platforms"]
    ).as_null_object
  end

  EXAMPLE_VALUE = {
    "data"      => { "name" => "OBS" },
    "platforms" => [{ "$value" => "Linux" }]
  }.freeze

  EXAMPLE_VALUE_WITH_MAIN = {
    "name"      => "OBS",
    "platforms" => [{ "$value" => "Linux" }]
  }.freeze

  describe "#value=" do
    let(:new_value) { EXAMPLE_VALUE }

    it "assigns the values to the items" do
      expect(item).to receive(:value=).with(new_value["data"])
      expect(sibling_item).to receive(:value=).with(new_value["platforms"])
      tree_pager.value = new_value
    end

    context "when one item is the main one" do
      let(:new_value) { EXAMPLE_VALUE_WITH_MAIN }

      let(:item) do
        instance_double(Y2ConfigurationManagement::Widgets::PagerTreeItem, main: true)
          .as_null_object
      end

      it "assigns the top level values to that item" do
        expect(item).to receive(:value=).with(new_value)
        tree_pager.value = new_value
      end
    end
  end

  describe "#value" do
    let(:new_value) { EXAMPLE_VALUE }

    it "returns the values from the pages" do
      expect(tree_pager.value).to eq(new_value)
    end

    context "when a main item is found" do
      let(:item) do
        instance_double(
          Y2ConfigurationManagement::Widgets::PagerTreeItem,
          main:  true,
          value: EXAMPLE_VALUE["data"]
        ).as_null_object
      end

      it "exports its values as the base of the hash" do
        expect(tree_pager.value).to eq(EXAMPLE_VALUE_WITH_MAIN)
      end
    end
  end

  describe "#widgets" do
    before do
      allow(tree_pager).to receive(:pages).and_return([page1, page2])
    end

    let(:page1) { double("page", children: [widget1]) }
    let(:widget1) { double("widget") }
    let(:page2) { double("page", children: [widget2]) }
    let(:widget2) { double("widget") }

    it "returns the widgets in the pages" do
      expect(tree_pager.widgets).to eq([widget1, widget2])
    end
  end

  describe "#store" do
    let(:page1) { double("page") }
    let(:page2) { double("page") }

    before do
      allow(tree_pager).to receive(:pages).and_return([page1, page2])
    end

    it "stores pages values" do
      expect(page1).to receive(:store)
      expect(page2).to receive(:store)
      tree_pager.store
    end
  end

  describe "#min_height" do
    let(:page1) { double("text", min_height: 3) }
    let(:page2) { double("collection", min_height: 2) }
    let(:text_mode) { false }

    before do
      allow(tree_pager).to receive(:pages).and_return([page1, page2])
      allow(Yast::UI).to receive(:TextMode).and_return(text_mode)
    end

    context "when running in textmode" do
      let(:text_mode) { true }

      it "returns 0" do
        expect(tree_pager.min_height).to eq(0)
      end
    end

    it "returns the max min_height of the underlying widgets" do
      expect(tree_pager.min_height).to eq(3)
    end
  end

  describe "#update_visibility" do
    let(:data) { Y2ConfigurationManagement::Salt::FormData.new({}) }
    let(:tree) do
      instance_double(
        Y2ConfigurationManagement::Widgets::Tree, refresh: nil, items: [item]
      )
    end

    before do
      allow(Y2ConfigurationManagement::Widgets::Tree).to receive(:new).and_return(tree)
    end

    it "update items visibility and refreshes the tree" do
      expect(item).to receive(:update_visibility)
      expect(tree).to receive(:refresh)
      tree_pager.update_visibility(data)
    end
  end
end
