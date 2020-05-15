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
require "y2configuration_management/salt/formulas_reader"

module Y2ConfigurationManagement
  module Salt
    # This class represents a [Salt Formula][1] present on disk
    #
    # [1]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Formula
      include Yast::Logger

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
