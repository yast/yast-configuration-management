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
require "y2configuration_management/salt/form_element_factory"

describe Y2ConfigurationManagement::Salt::FormElementFactory do
  subject(:factory) { described_class.new }
  let(:parent) { instance_double(Y2ConfigurationManagement::Salt::Container) }

  describe "#build" do
    let(:spec) do
      { "$type" => "boolean" }
    end

    context "given a simple element spec" do
      it "returns a FormInput element" do
        element = factory.build("field", spec)
        expect(element).to be_a(Y2ConfigurationManagement::Salt::FormInput)
        expect(element.id).to eq("field")
        expect(element.type).to eq(:boolean)
      end
    end

    context "when a parent element is given" do
      it "sets the parent" do
        element = factory.build("field", spec, parent: parent)
        expect(element.parent).to eq(parent)
      end
    end

    context "given a group element spec" do
      let(:spec) do
        {
          "$type" => "group",
          "name" => { "$type" => "text" }
        }
      end

      it "returns a container element" do
        element = factory.build("field", spec)
        expect(element).to be_a(Y2ConfigurationManagement::Salt::Container)
        expect(element.id).to eq("field")
      end
    end

    context "given a namespace spec" do
      let(:spec) do
        {
          "$type" => "namespace",
          "name" => { "$type" => "text" }
        }
      end

      it "returns a container element" do
        element = factory.build("field", spec)
        expect(element).to be_a(Y2ConfigurationManagement::Salt::Container)
        expect(element.id).to eq("field")
      end
    end

    context "when the type is not specified" do
      context "and more than 1 field is defined" do
        let(:spec) do
          { 

            "name" => { "$type" => "text" },
            "email" => { "$type" => "text" }
          }
        end

        it "returns a container element" do
          element = factory.build("field", spec)
          expect(element).to be_a(Y2ConfigurationManagement::Salt::Container)
        end
      end

      context "and just 1 field is defined" do
        let(:spec) do
          { "name" => { "$type" => "text" } }
        end

        it "returns a FormInput element" do
          element = factory.build("field", spec)
          expect(element).to be_a(Y2ConfigurationManagement::Salt::FormInput)
        end
      end
    end
  end
end

