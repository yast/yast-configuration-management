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

module Y2ConfigurationManagement
  module Salt
    # Reads formulas from a set of given directories
    #
    # @example Reading SUMA formulas
    #   reader = FormulasReader.new("/usr/share/susemanager/formulas/metadata")
    #   reader.formulas #=> [#<Formula:...>, #<Formula:...>]
    #
    # @example Reading formulas from several locations
    #   reader = FormulasReader.new(["/usr/share/susemanager/formulas/metadata", "/srv/formulas"])
    #   reader.formulas #=> [#<Formula:...>, #<Formula:...>]
    class FormulasReader
      # @return [Array<String>] Paths to read formulas from
      attr_reader :paths

      # Constructor
      #
      # @param paths  [Array<String>|String] File system paths to search for formulas
      def initialize(*paths)
        @paths = paths
      end

      # @return [Array<Formula>]
      def formulas
        metadata_paths = paths.flatten.compact.empty? ? formula_directories : paths.flatten.compact
        Dir.glob(metadata_paths.map { |p| p + "/*" })
          .map { |p| Pathname.new(p) }
          .select(&:directory?)
          .map { |p| Formula.new(p) }
          .select(&:form)
      end
    end
  end
end
