#!/usr/bin/env rspec
# encoding: utf-8

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
require "y2configuration_management/widgets/form"
require "y2configuration_management/widgets/text"

describe Y2ConfigurationManagement::Widgets::Form do
  subject(:form) { described_class.new([text_input]) }
  let(:text_input) do
    instance_double(Y2ConfigurationManagement::Widgets::Text, id: "text1", value: "foobar")
  end

  describe "#value" do
    it "sets values for underlying widgets" do
      expect(text_input).to receive(:value=).with("example")
      form.value = { "text1" => "example" }
    end
  end

  describe "#store" do
    it "stores the final result" do
      form.store
      expect(form.result).to eq("text1" => "foobar")
    end
  end
end