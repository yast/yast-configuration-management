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
      class ParseError < RuntimeError
      end

      # @param s [String]
      # @param context [FormElementLocator] for resolving relative expressions
      def self.parse(s, context:)
        if s.empty?
          nil
        # This matches checkVisibilityCondition in FormulaComponentGenerator.js
        # TODO: specify it better
        elsif s.include?("==")
          parts = s.split("==").map(&:strip)
          locator = parse_locator(parts[0].strip, context)
          value = parse_value(parts[1].strip)
          EqualCondition.new(locator: locator, value: value)
        elsif s.include?("!=")
          parts = s.split("!=").map(&:strip)
          locator = parse_locator(parts[0], context)
          value = parse_value(parts[1])
          NotEqualCondition.new(locator: locator, value: value)
        else
          raise ParseError, "Expecting equality or inequality: #{s.inspect}"
        end
      end

      def self.parse_locator(s, context)
        if s.start_with? "."
          while s.start_with? "."
            s = s[1..-1]
            context = context.parent
          end
        else
          context = FormElementLocator.new([:root])
        end
        s_parts = s.split("#").map(&:to_sym)
        context.join(* s_parts)
      end

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
      def evaluate(data)
        left = data.get(@locator).to_s
        right = @value.to_s
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
