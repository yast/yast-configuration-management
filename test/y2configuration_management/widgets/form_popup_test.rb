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
require "cwm/rspec"
require "y2configuration_management/widgets/form_popup"

describe Y2ConfigurationManagement::Widgets::FormPopup do
  class EmptyWidget < CWM::AbstractWidget
    self.widget_type = :empty
  end

  let(:subject) { described_class.new("popup", EmptyWidget.new) }
  include_examples "CWM::Dialog"

  describe "#layout" do
    it "returns a Yast::Term" do
      expect(subject.send(:layout)).to be_a(Yast::Term)
    end
  end
end
