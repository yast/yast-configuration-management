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
    # The locator can be seen as a path to the form element. In a human readable form, the locator
    # looks like: "root#person#computers[1]" or "root#hosts[router]".
    #
    # @example Building a locator from a string for an array based collection
    #   locator = FormElementLocator.from_string("root#person#computers[1]")
    #   locator.to_s  #=> "root#person#computers[1]"
    #   locator.parts #=> [:root, :person, :computers, 1]
    #
    # @example Building a locator from a string for a hash based collection
    #   locator = FormElementLocator.from_string("root#hosts[router]")
    #   locator.to_s  #=> "root#hosts[router]"
    #   locator.parts #=> [:root, :hosts, "router"]
    #
    # @example Building a locator from its parts
    #   locator = FormElementLocator.new(:root, :hosts, "router")
    #   locator.to_s #=> "root#hosts[router]"
    #
    # @example Extending a locator
    #   locator = FormElementLocator.new(:root, :hosts, "router")
    #   locator.join(:interfaces).to_s #=> "root#hosts[router]#interfaces"
    class FormElementLocator
      extend Forwardable

      def_delegators :@parts, :first, :last

      class << self
        # Builds a locator from a string
        #
        # @todo Support specifying dots within hash keys (e.g. `.hosts[download.opensuse.org]`).
        #
        # @param string [String] String representing an element locator
        # @return [FormElementLocator]
        def from_string(string)
          string.scan(TOKENS).reduce(nil) do |locator, part|
            new_locator = from_part(part)
            locator ? locator.join(from_part(part)) : new_locator
          end
        end

      private

        # @return [String] Locator segments separator
        SEPARATOR = "#".freeze

        # @return [Regexp] Regular expresion to extract locator segments
        TOKENS = /(?:\[.*?\]|[^#{SEPARATOR}\[])+/

        # @return [Regexp] Regular expression representing a indexed locator segment
        INDEXED_SEGMENT = /([^\[]+)(?:\[(.+)\])?/

        # @return []
        SEGMENT = /(\.*)#{INDEXED_SEGMENT}/

        # Parses a locator part
        #
        # @param string [String]
        # @return [Array<Integer,String,Symbol>] Locator subparts
        def from_part(string)
          match = SEGMENT.match(string)
          return nil unless match
          prefix, path, index = match[1..3]

          ids = index.to_s.split("][").map do |id|
            numeric_id?(id) ? id.to_i : id
          end

          parts = [path.to_sym] + ids
          FormElementLocator.new(parts, upto: prefix.size)
        end

        # Determines whether the id is numeric or not
        #
        # @return [Boolean]
        def numeric_id?(id)
          id =~ /\A\d+\z/
        end
      end

      # @return [Array<Integer,String,Symbol>] Locator parts
      attr_reader :parts

      # Zero for absolute locators, nonzero for relative ones
      # @return [Integer] how many levels up do we go for a relative locator
      attr_reader :upto

      # Constructor
      #
      # @param parts [Array<Integer,String,Symbol>] Locator parts
      def initialize(parts, upto: 0)
        @parts = parts
        @upto = upto
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
        as_string = parts.reduce("") do |memo, part|
          part_as_string = part.is_a?(Symbol) ? "##{part}" : "[#{part}]"
          memo << part_as_string
        end
        prefix = relative? ? "." * upto : ""
        prefix + as_string[1..-1]
      end

      # Extends a locator
      #
      # @param locators_or_parts [FormElementLocator,Integer,String,Symbol] Parts or locators
      #   to join
      # @return [Locator] Augmented locator
      def join(*locators_or_parts)
        locators_or_parts.reduce(self) do |locator, item|
          other = item.is_a?(FormElementLocator) ? item : FormElementLocator.new([item])
          locator.join_with_locator(other)
        end
      end

      # Determines whether two locators are equivalent
      #
      # @param other [Locator] Locator to compare with
      # @return [Boolean] true if both locators are equal; false otherwise
      def ==(other)
        upto == other.upto && parts == other.parts
      end

      # Removes references to specific collection elements
      #
      # @return [FormElementLocator]
      def unbounded
        self.class.new(parts.select { |i| i.is_a?(Symbol) })
      end

      # Determines whether a locator is relative or not
      #
      # @return [Boolean] true if its relative; false otherwise
      def relative?
        !upto.zero?
      end

    protected

      # Extends a locator with another one
      #
      # @param other [FormElementLocator] Locator to join
      # @return [Locator] Augmented locator
      # @see join
      def join_with_locator(other)
        limit = -1 - other.upto
        self.class.new(parts[0..limit] + other.parts, upto: upto)
      end
    end
  end
end
