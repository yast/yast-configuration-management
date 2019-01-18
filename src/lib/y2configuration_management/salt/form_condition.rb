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

module Y2ConfigurationManagement
  module Salt
    # A boolean condition operating on a value in the form,
    # used for widget visibility ($visibleIf).
    class FormCondition
      # @param s [String]
      # @param context [] for resolving relative expressions
      def self.parse(s, _context: nil)
        if s.empty?
          nil
        else
          # FIXME: parser

          # also, how to handle errors in forms, specifying a nonexisting element?
          # Handle it in #parse, probably as a hard error
          locator = FormElementLocator.from_string ".root.branch_network.dedicated_NIC"
          EqualCondition.new(locator: locator, value: true)
        end
      end
    end

    # A {FormCondition} checking if a widget is equal to a constant
    class EqualCondition < FormCondition
      def initialize(locator:, value:)
        @locator = locator
        @value = value
      end

      # @param data [FormData]
      def evaluate(data)
        left = data.get(@locator)
        right = @value
        left == right
      end
    end

    # A {FormCondition} checking if a widget is not equal to a constant
    class NotEqualCondition < EqualCondition
      def evaluate(data)
        !super
      end
    end
  end
end
