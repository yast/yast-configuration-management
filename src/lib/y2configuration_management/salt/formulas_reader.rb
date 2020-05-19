# Copyright (c) [2020] SUSE LLC
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

require "y2configuration_management/salt/formula"
require "pathname"

module Y2ConfigurationManagement
  module Salt
    # Reads formulas from a given location
    #
    # @example Reading SUMA formulas
    #   reader = FormulasReader.new("/usr/share/susemanager/formulas/metadata")
    #   reader.formulas #=> [#<Formula:...>, #<Formula:...>]
    #
    # @example Reading formulas from several locations
    #   reader = FormulasReader.new(["/usr/share/susemanager/formulas/metadata", "/srv/formulas"])
    #   reader.formulas #=> [#<Formula:...>, #<Formula:...>]
    class FormulasReader
      attr_reader :metadata_root
      attr_reader :pillar_root

      # Constructor
      #
      # @param metadata_root [Pathname] Path to the metadata directory
      # @param pillar_root [Pathname] Path to pillar data directory
      def initialize(metadata_root, pillar_root)
        @metadata_root = Pathname(metadata_root)
        @pillar_root = Pathname(pillar_root)
      end

      # Returns the formulas in the {#metadata_root} directory
      #
      # It searches for the pillar data under {#pillar_root} directory.
      #
      # @return [Array<Formula>]
      def formulas
        directories = metadata_root.glob("*").select(&:directory?)
        directories.each_with_object([]) do |dir, found_formulas|
          formula = Formula.new(dir)
          next unless formula.form
          formula.pillar = pillar_for(formula)
          found_formulas << formula
        end
      end

    private

      # Convenience method for reading the {Pillar} associated to the given
      # formula
      #
      # @param formula [Formula]
      # @return [Pillar]
      def pillar_for(formula)
        path = pillar_root.join("#{formula.id}.sls")
        pillar = Y2ConfigurationManagement::Salt::Pillar.new(path: path)
        pillar.load
        pillar
      end
    end
  end
end
