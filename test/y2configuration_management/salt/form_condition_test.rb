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
require "y2configuration_management/salt/form_condition"
require "y2configuration_management/salt/form_element_locator"
require "y2configuration_management/salt/form_data"

describe Y2ConfigurationManagement::Salt::FormCondition do
  def locator_new(*args)
    Y2ConfigurationManagement::Salt::FormElementLocator.new(*args)
  end

  let(:context_loc) { locator_new([:root, :foo, :bar]) }

  describe ".parse" do
    it "parses the empty string as a nil condition" do
      expect(described_class.parse("")).to eq(nil)
    end

    it "raises on an unparsable string" do
      expect { described_class.parse("***") }.to raise_error(RuntimeError)
    end
  end

  describe ".parse_value" do
    it "parses a non-quoted string" do
      expect(described_class.parse_value("foo")).to eq("foo")
    end

    it "parses a single-quoted string" do
      expect(described_class.parse_value("'foo'")).to eq("foo")
    end

    it "parses a double-quoted string" do
      expect(described_class.parse_value("\"foo\"")).to eq("foo")
    end

    it "does not unescape the contents" do
      expect(described_class.parse_value("\"fo\\\"o\"")).to eq("fo\\\"o")
    end
  end

  describe Y2ConfigurationManagement::Salt::EqualCondition do
    describe "#evaluate" do
      subject(:condition) { described_class.parse("myform#mywidget == '42'") }

      let(:ctxt) { double("form element", locator: context_loc) }
      let(:data) { double("form data") }

      it "compares the string representations" do
        expect(data).to receive(:get)
          .with(locator_new([:myform, :mywidget]))
          .and_return(Y2ConfigurationManagement::Salt::FormData.new(42))
        expect(condition.evaluate(data, context: ctxt)).to eq(true)
      end

      context "when a relative locator is given" do
        subject(:condition) { described_class.parse(".mywidget == '42'") }

        it "uses joins the context locator and the condition one" do
          expect(data).to receive(:get)
            .with(locator_new([:root, :foo, :mywidget]))
            .and_return(Y2ConfigurationManagement::Salt::FormData.new(42))
          expect(condition.evaluate(data, context: ctxt)).to eq(true)
        end
      end
    end
  end

  describe Y2ConfigurationManagement::Salt::NotEqualCondition do
    describe "#evaluate" do
      subject(:condition) { described_class.parse("myform#mywidget != '42'") }

      let(:ctxt) { double("form element", locator: context_loc) }
      let(:data) { double("form data") }

      it "compares the string representations" do
        expect(data).to receive(:get).with(locator_new([:myform, :mywidget]))
          .and_return(Y2ConfigurationManagement::Salt::FormData.new(42))
        expect(condition.evaluate(data, context: ctxt)).to eq(false)
      end

      context "when the locator is relative" do
        subject(:condition) { described_class.parse(".mywidget != '42'") }

        it "uses joins the context locator and the condition one" do
          expect(data).to receive(:get)
            .with(locator_new([:root, :foo, :mywidget]))
            .and_return(Y2ConfigurationManagement::Salt::FormData.new(42))
          expect(condition.evaluate(data, context: ctxt)).to eq(false)
        end
      end
    end
  end
end
