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
require "y2configuration_management/widgets/pager_tree_item"
require "y2configuration_management/widgets/page"
require "y2configuration_management/salt/form_condition"
require "y2configuration_management/salt/form_data"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::PagerTreeItem do
  subject(:item) do
    described_class.new(
      page, children: [nested_item], visible_if: form_condition
    ).tap { |i| i.tree = tree }
  end

  let(:page) do
    instance_double(
      Y2ConfigurationManagement::Widgets::Page, label: "Projects", id: "projects",
      value: { "name" => "YaST2" }
    ).as_null_object
  end
  let(:nested_item) { described_class.new(nested_page) }
  let(:nested_page) do
    instance_double(
      Y2ConfigurationManagement::Widgets::Page, id: "labels", value: [{ "$value" => "Linux" }]
    ).as_null_object
  end
  let(:tree) { double("tree") }

  let(:form_condition) do
    Y2ConfigurationManagement::Salt::FormCondition.parse(".item == true")
  end

  include_examples "CWM::AbstractWidget"

  describe "#page_id" do
    it "returns the page's id" do
      expect(item.page_id).to eq("projects")
    end
  end

  describe "#value" do
    it "returns values from pages" do
      expect(item.value).to eq("name" => "YaST2", "labels" => nested_page.value)
    end
  end

  describe "#value=" do
    let(:new_value) do
      { "name" => "OBS", "labels" => [{ "$value" => "building" }] }
    end

    it "propagates the values to the pages" do
      expect(page).to receive(:value=).with("name" => "OBS")
      expect(nested_page).to receive(:value=).with(new_value["labels"])
      item.value = new_value
    end
  end

  describe "#tree" do
    it "returns the tree where it belongs" do
      expect(item.tree).to eq(tree)
    end

    context "when the item is nested" do
      it "returns its parent tree" do
        nested = item.items.first
        expect(nested.tree).to eq(tree)
      end
    end
  end

  describe "#update_visibility" do
    let(:data) { Y2ConfigurationManagement::Salt::FormData.new({}) }

    before do
      allow(form_condition).to receive(:evaluate)
        .with(data, context: item).and_return(visible?)
    end

    context "when visibility condition evaluates to true" do
      let(:visible?) { true }

      it "sets the items as visible" do
        item.update_visibility(data)
        expect(item).to be_visible
      end

      it "asks children to set their visibility" do
        expect(nested_item).to receive(:update_visibility)
        item.update_visibility(data)
      end
    end

    context "when visibility condition evaluates to false" do
      let(:visible?) { false }

      it "sets the items as not visible" do
        item.update_visibility(data)
        expect(item).to_not be_visible
      end

      it "sets the children as not visible" do
        item.update_visibility(data)
        expect(nested_item).to_not be_visible
      end
    end
  end
end
