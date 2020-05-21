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
require "y2configuration_management/widgets/tree"
require "y2configuration_management/widgets/pager_tree_item"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::Tree do
  subject(:tree) { described_class.new([item1, item2], pager) }
  let(:item1) do
    instance_double(
      Y2ConfigurationManagement::Widgets::PagerTreeItem,
      "item1", visible?: true, ui_term: Yast::Term.new(:item1, [])
    ).as_null_object
  end

  let(:item2) do
    instance_double(
      Y2ConfigurationManagement::Widgets::PagerTreeItem,
      "item2", visible?: false
    ).as_null_object
  end
  let(:pager) { double("pager") }

  include_examples "CWM::CustomWidget"

  describe "#pager" do
    it "returns the associated pager" do
      expect(tree.pager).to eq(pager)
    end
  end

  describe "#contents" do
    it "only display visible items" do
      expect(item2).to_not receive(:ui_term)
      tree.contents
    end
  end
end
