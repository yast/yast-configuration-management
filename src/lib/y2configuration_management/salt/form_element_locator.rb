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

require "forwardable"

module Y2ConfigurationManagement
  module Salt
    # Represent the locator to a form element
    #
    # The locator can be seen as a path to the form element.
    #
    # @example Building a locator from a string
    #   locator = FormElementLocator.from_string(".root.person.computers[1]")
    #   locator.to_s  #=> ".root.person.computers[1]"
    #   locator.parts #=> ["root", "person", "computers", 1]
    class FormElementLocator
      extend Forwardable

      def_delegators :@parts, :first, :last

      class << self
        # Builds a locator from a string
        #
        # @param string [String] String representing an element locator
        # @return [FormElementLocator]
        def from_string(string)
          parts = string[1..-1].split(".").each_with_object([]) do |part, all|
            all.concat(from_part(part))
          end
          new(parts)
        end

      private

        # @return [Regexp] Regular expression representing a locator part
        INDEXED_PART = /\A(\w+)\[(\d+)\]\z/

        # Parses a locator part
        #
        # @param string [String]
        # @return [Array<String,Integer>] Locator subparts
        def from_part(string)
          match = INDEXED_PART.match(string)
          return [string] unless match
          [match[1], match[2].to_i]
        end
      end

      # @return [Array<Integer,String>] Locator parts
      attr_reader :parts

      # Constructor
      #
      # @param parts [Array<Integer,String>] Locator parts
      def initialize(parts)
        @parts = parts
      end

      # Locator of the parent element
      #
      # @return [Locator] Locator's parent
      def parent
        self.class.new(parts[0..-2])
      end

      # Removes the first part of the locator
      #
      # @return [Locator] Locator without the prefix
      def rest
        self.class.new(parts[1..-1])
      end

      # Returns the string representation
      #
      # @return [String] String representation
      def to_s
        parts.reduce("") do |memo, part|
          part_as_string = part.is_a?(Integer) ? "[#{part}]" : ".#{part}"
          memo << part_as_string
        end
      end

      # Extends a locator
      #
      # @param locators_or_parts [FormElementLocator,String,Integer] Parts or locators to join
      # @return [Locator] Augmented locator
      def join(*locators_or_parts)
        new_parts = locators_or_parts.reduce([]) do |all, item|
          item_parts = item.respond_to?(:parts) ? item.parts : [item]
          all + item_parts
        end
        self.class.new(parts + new_parts)
      end

      # Determines whether two locators are equivalent
      #
      # @param other [Locator] Locator to compare with
      # @return [Boolean] true if both locators are equal; false otherwise
      def ==(other)
        parts == other.parts
      end

      # Removes references to specific collection elements
      #
      # @return [FormElementLocator]
      def unbounded
        self.class.new(parts.reject { |i| i.is_a?(Integer) })
      end
    end
  end
end
