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
  subject(:datetime) { described_class.new(spec, locator) }
  let(:form_spec) { { "deadline" => { "$type" => "datetime" } } }
  let(:form) { Y2ConfigurationManagement::Salt::Form.new(form_spec) }
  let(:spec) { form.find_element_by(locator: locator) }
  let(:locator) { locator_from_string("root#deadline") }
  let(:yast_release) { "#{yast_release_date} #{yast_release_time}" }
  let(:yast_release_date) { "1996-05-01" }
  let(:yast_release_time) { "16:30:00" }
  let(:date) { datetime.send(:date) }
  let(:time) { datetime.send(:time) }
  include_examples "CWM::CustomWidget"

  describe "#init" do
    context "when the datetime has already a cached value" do
      before do
        datetime.value = yast_release
      end

      it "inits the widget value with the cached one" do
        expect(datetime).to receive(:value=).with(yast_release)
        datetime.init
      end
    end

    context "when the datetime does not have a cached value" do
      it "inits the widget value with the default one" do
        expect(datetime).to receive(:value=).with("")
        datetime.init
      end
    end
  end

  describe "value" do
    before do
      allow(date).to receive(:value).and_return(yast_release_date)
      allow(time).to receive(:value).and_return(yast_release_time)
    end

    it "returns the joined date field and time field values" do
      expect(datetime.value).to eql(yast_release)
    end
  end

  describe "#value=" do
    let(:value) { yast_release }
    let(:date) { datetime.send(:date) }
    let(:time) { datetime.send(:time) }

    before do
      allow(date).to receive(:value).and_return(yast_release_date)
      allow(time).to receive(:value).and_return(yast_release_time)
    end

    it "sets the date field with the parsed date" do
      expect(date).to receive(:value=).with(yast_release_date)
      datetime.value = value
    end

    it "sets the time field with the parsed time" do
      expect(time).to receive(:value=).with(yast_release_time)
      subject.value = value
    end

    it "caches the value of the date and time fields" do
      subject.value = value
      expect(subject).to_not receive(:default)
      subject.init
    end
  end

  describe "#contents" do
    it "contains a DateField and a TimField" do
      date_widget = subject.contents.nested_find { |i| i.is_a?(::CWM::DateField) }
      time_widget = subject.contents.nested_find { |i| i.is_a?(::CWM::TimeField) }

      expect(date_widget).to_not eql(nil)
      expect(time_widget).to_not eql(nil)
    end
  end
end
