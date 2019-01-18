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
require "y2configuration_management/salt/form_element_locator"

describe Y2ConfigurationManagement::Salt::FormElementLocator do
  subject(:locator) { described_class.new(["root", "hosts", 1, "interfaces", 3]) }

  describe "#from_string" do
    it "extracts the parts" do
      locator = described_class.from_string(".root.person.computers[2].model")
      expect(locator.parts).to eq(
        ["root", "person", "computers", 2, "model"]
      )
    end
  end

  describe "#to_s" do
    it "returns the string representation of the element locator" do
      expect(locator.to_s).to eq(".root.hosts[1].interfaces[3]")
    end
  end

  describe "#first" do
    it "returns the first part of the locator" do
      expect(locator.first).to eq("root")
    end
  end

  describe "#last" do
    it "returns the last part of the locator" do
      expect(locator.last).to eq(3)
    end
  end

  describe "#rest" do
    it "returns the locator without the prefix" do
      expect(locator.rest).to eq(locator_from_string(".hosts[1].interfaces[3]"))
    end
  end

  describe "#join" do
    it "returns a new locator including the given parts" do
      address_locator = locator.join("address", "type")
      expect(address_locator.parts).to eq(["root", "hosts", 1, "interfaces", 3, "address", "type"])
    end

    it "returns a new locator adding the given locator" do
      address_locator = locator.join(locator_from_string(".address.type"))
      expect(address_locator.parts).to eq(["root", "hosts", 1, "interfaces", 3, "address", "type"])
    end
  end

  describe "#unbounded" do
    it "removes specific elements" do
      expect(locator.unbounded.to_s).to eq(".root.hosts.interfaces")
    end
  end
end
