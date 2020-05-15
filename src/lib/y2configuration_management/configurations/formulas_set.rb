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

require "pathname"

module Y2ConfigurationManagement
  module Configurations
    # Ancillary class to define the details of where a set of formulas are located
    #
    # It contains the path to the components of the formula: metadata, states and pillar
    # directories.
    class FormulasSet
      # @return [Pathname]
      attr_reader :metadata_root
      # @return [Pathname,nil]
      attr_reader :states_root
      # @return [Pathname,nil]
      attr_reader :pillar_root

      # Constructor
      #
      # @param metadata_root [Pathname] Directory where formulas metadata is located
      # @param states_root [Pathname,nil] Directory where the states are located
      # @param pillar_root [Pathname,nil] Directory where the pillar data is stored
      def initialize(metadata_root, states_root = nil, pillar_root = nil)
        @metadata_root = Pathname.new(metadata_root) if metadata_root
        @states_root = Pathname.new(states_root) if states_root
        @pillar_root = Pathname.new(pillar_root) if pillar_root
      end
    end
  end
end
