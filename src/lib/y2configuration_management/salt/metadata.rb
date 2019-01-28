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

require "yaml"
require "yast"

module Y2ConfigurationManagement
  module Salt
    # [Metadata][1] of [Salt Formulas][2].
    #
    # [1]: https://www.suse.com/documentation/suse-manager-3/3.2/susemanager-best-practices/html/book.suma.best.practices/best.practice.salt.formulas.and.forms.html#best.practice.salt.formulas.pillar
    # [2]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Metadata
      include Yast::Logger
      # @return [String] Formula description
      attr_reader :description
      # @return [String] Formula group
      attr_reader :group
      # @return [String]
      attr_reader :after

      # Constructor
      #
      # The original specification (deserialized metadata.yml).
      #
      # @param spec [Hash] The original specification (deserialized metadata.yml).
      def initialize(spec)
        @spec = spec
        @description = spec.fetch("description", "")
        @group = spec.fetch("group", "")
        @after = spec.fetch("after", "")
      end

      # Creates a new {Metadata} object reading the definition from a YAML file
      #
      # @param path [String] file path to read the form YAML definition
      # @return [Metadata, nil]
      def self.from_file(path)
        definition = YAML.safe_load(File.read(path))
        new(definition)
      rescue IOError, SystemCallError, RuntimeError => error
        log.error("Reading #{path} failed with exception: #{error.inspect}")
        nil
      end
    end
  end
end
