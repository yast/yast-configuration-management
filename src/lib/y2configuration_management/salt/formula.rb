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
require "fileutils"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/metadata"
require "y2configuration_management/salt/pillar"

module Y2ConfigurationManagement
  module Salt
    # This class represents a [Salt Formula][1] present on disk
    #
    # [1]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Formula
      include Yast::Logger

      # Default path to formulas repository. SuMa *-formula.rpm put them there
      BASE_DIR = "/usr/share/susemanager/formulas".freeze
      # Custom formulas metadada directory
      # @see https://www.suse.com/documentation/suse-manager-3/singlehtml/book_suma_best_practices_31/book_suma_best_practices_31.html#best.practice.salt.formulas.filedir
      CUSTOM_METADATA_DIR = "/srv/formula_metadata".freeze
      # Saved data directory
      # @see https://www.suse.com/documentation/suse-manager-3/singlehtml/book_suma_best_practices_31/book_suma_best_practices_31.html#best.practice.salt.formulas.req
      DATA_DIR = "/srv/susemanager/formula_data".freeze

      # @return [Pathname] Formula path
      attr_reader :path

      # @return [Metadata] Formula metadata
      attr_reader :metadata

      # @return [Form] Formula form
      attr_reader :form

      # @return [Pillar] Formula pillar
      attr_accessor :pillar

      # Constructor
      #
      # @param path [Pathname]
      # @param pillar [Pillar] associated formula data
      def initialize(path, pillar = nil)
        @path = path
        @metadata = Metadata.from_file(@path.join("metadata.yml"))
        @form = Form.from_file(@path.join("form.yml"))
        @pillar = pillar
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
      # @note The result is cached. To force refreshing the cache, set the `reload`
      #   parameter to `true`.
      #
      # @param paths  [Array<String>|String] File system paths to search for formulas
      # @param reload [Boolean] Refresh formulas cache
      # @return [Array<Formula>]
      def self.all(*paths, reload: false)
        return @formulas if @formulas && !reload
        metadata_paths = paths.flatten.compact.empty? ? formula_directories : paths.flatten.compact
        @formulas =
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
        [BASE_DIR + "/metadata", CUSTOM_METADATA_DIR]
      end

      # Convenience method for writing the associated {Pillar}
      #
      # @return [Boolean] whether the pillar was written or not
      def write_pillar
        return false unless pillar
        pillar.save
      end
    end
  end
end
