#!/usr/bin/env rspec

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
require "y2configuration_management/salt/formula_selection"
require "y2configuration_management/salt/formula"

require "cwm/rspec"

describe Y2ConfigurationManagement::Salt::FormulaSelection do
  include_examples "CWM::Dialog"
  let(:formulas_root) { FIXTURES_PATH.join("formulas-ng") }
  let(:form) { formulas_root.join("form.yml") }
  let(:formulas) { Y2ConfigurationManagement::Salt::Formula.all(formulas_root.to_s) }
  subject { described_class.new(formulas) }

  describe "#run" do
    context "when some formula has been selected" do
      before do
        allow_any_instance_of(CWM::Dialog).to receive(:run).and_return(:next)
        formulas.each { |f| allow(f).to receive(:enabled?).and_return(true) }
      end

      it "return the dialog result" do
        expect(Yast::Report).to_not receive(:Error)
        expect(subject.run).to eql(:next)
      end
    end

    context "when no formula has been selected" do
      let(:formulas) { [] }
      before do
        allow_any_instance_of(CWM::Dialog).to receive(:run).and_return(:next)
        allow(Yast::Report).to receive(:Error)
      end

      it "reports an error requesting to choose at least one formula to continue" do
        expect(subject).to receive(:continue?).and_return(false, true)
        expect(Yast::Report).to receive(:Error).once.and_return(true)
        subject.run
      end
    end
  end

  describe "#disable_buttons" do
    it "disables the back button" do
      expect(subject.disable_buttons).to eql(["back_button"])
    end
  end
end
