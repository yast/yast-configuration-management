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

require "y2configuration_management/salt/form_element_locator"

module Y2ConfigurationManagement
  module Salt
    # A boolean condition operating on a value in the form,
    # used for widget visibility ($visibleIf).
    class FormCondition
      class ParseError < RuntimeError
      end

      # @param s [String]
      # @return [FormCondition,nil]
      def self.parse(s)
        if s.empty?
          nil
        # This matches checkVisibilityCondition in FormulaComponentGenerator.js
        # TODO: specify it better
        elsif s.include?("==")
          parts = s.split("==").map(&:strip)
          locator = FormElementLocator.from_string(parts[0].strip)
          value = parse_value(parts[1].strip)
          EqualCondition.new(locator: locator, value: value)
        elsif s.include?("!=")
          parts = s.split("!=").map(&:strip)
          locator = FormElementLocator.from_string(parts[0])
          value = parse_value(parts[1])
          NotEqualCondition.new(locator: locator, value: value)
        else
          raise ParseError, "Expecting equality or inequality: #{s.inspect}"
        end
      end

      # @param s [String]
      # @return [String] (conditions compare stringified values)
      def self.parse_value(s)
        if (s[0] == "'" && s[-1] == "'") || (s[0] == "\"" && s[-1] == "\"")
          s[1..-2]
        else
          s
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
      # @param context [FormElement] for resolving relative expressions
      def evaluate(data, context:)
        left_locator = @locator.relative? ? context.locator.join(@locator) : @locator
        left = data.get(left_locator).to_s
        right = @value.to_s
        left == right
      end
    end

    # A {FormCondition} checking if a widget is not equal to a constant
    class NotEqualCondition < EqualCondition
      # @param data [FormData]
      # @param context [FormElement] for resolving relative expressions
      def evaluate(data, context:)
        !super
      end
    end
  end
end
