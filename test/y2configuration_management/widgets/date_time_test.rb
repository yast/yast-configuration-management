#!/usr/bin/env rspec
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
require "y2configuration_management/widgets/date_time"
require "y2configuration_management/salt/form"
require "cwm/rspec"

describe Y2ConfigurationManagement::Widgets::DateTime do
  subject(:datetime) { described_class.new(spec) }
  let(:form_spec) { { "deadline" => { "$type" => "datetime" } } }
  let(:form) { Y2ConfigurationManagement::Salt::Form.new(form_spec) }

  let(:spec) { form.find_element_by(locator: locator) }
  let(:locator) { locator_from_string(".root.deadline") }

  include_examples "CWM::CustomWidget"

  describe "#contents" do
    it "contains a DateField and a TimField" do
      date_widget = subject.contents.nested_find { |i| i.is_a?(::CWM::DateField) }
      time_widget = subject.contents.nested_find { |i| i.is_a?(::CWM::TimeField) }

      expect(date_widget).to_not eql(nil)
      expect(time_widget).to_not eql(nil)
    end
  end
end
