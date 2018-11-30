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
  let(:formulas_root) { FIXTURES_PATH.join("formulas") }
  let(:form) { formulas_root.join("form.yml") }
  let(:formulas) { Y2ConfigurationManagement::Salt::Formula.all(formulas_root) }
  subject { described_class.new(formulas) }
end
