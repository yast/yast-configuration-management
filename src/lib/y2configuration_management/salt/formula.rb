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
require "pathname"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/metadata"

module Y2ConfigurationManagement
  module Salt
    # This class represents a [Salt Formula][1] present on disk
    #
    # [1]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Formula
      include Yast::Logger

      # Default path to formulas repository
      FORMULA_BASE_DIR = "/usr/share/susemanager/formulas".freeze
      FORMULA_CUSTOM_DIR = "/srv/susemanager/formulas".freeze
      FORMULA_DATA = "/srv/susemanager/formula_data".freeze

      # @return [String] Formula path
      attr_reader :path

      # @return [Metadata] Formula metadata
      attr_reader :metadata

      # @return [Form] Formula form
      attr_reader :form

      # Constructor
      #
      # @param path [String]
      def initialize(path)
        @path = path
        @metadata = Metadata.from_file(File.join(@path, "metadata.yml"))
        @form = Form.from_file(File.join(@path, "form.yml"))
        @enabled = false
      end

      # whether to apply this formula
      #
      # @return [Boolean]
      def enabled?
        @enabled
      end

      attr_writer :enabled

      # Formula ID
      #
      # @return [String]
      def id
        path.basename.to_s
      end

      # Formula description
      #
      # @return [String]
      def description
        metadata ? metadata.description : ""
      end

      # Return all the installed formulas
      #
      # @return [Array<Formula>]
      def self.all(*paths)
        metadata_paths = paths.flatten.compact.empty? ? formula_directories : paths.flatten.compact
        Dir.glob(metadata_paths.map { |p| p + "/*" })
           .map { |p| Pathname.new(p) }
           .select(&:directory?)
           .map { |p| Formula.new(p) }
           .select(&:form)
      end

      # Return formula default directories
      #
      # @return [String]
      def self.formula_directories
        [FORMULA_BASE_DIR + "/metadata", FORMULA_CUSTOM_DIR]
      end
    end
  end
end
