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
    # This class represents a Saltstack [Pillar][1]
    #
    # [1]: https://docs.saltstack.com/en/latest/topics/tutorials/pillar.html
    class Pillar
      include Yast::Logger
      # @return [Object] Pillar data
      attr_accessor :data

      # @return [String] Pillar file path
      attr_accessor :path

      # Constructor
      #
      # @param data [Hash] The pillar data (deserialized pillar_name.yml).
      def initialize(data: {}, path: "")
        @data = data
        @path = path
      end

      # Creates a new {Pillar} object reading its data from a YAML file
      #
      # @param path [String] file path to read the form YAML definition
      # @return [Metadata, nil]
      def self.from_file(path)
        pillar = new(data: {}, path: path)
        pillar.load ? pillar : nil
      end

      def load
        @data = YAML.safe_load(File.read(path))
      rescue IOError, SystemCallError, RuntimeError => error
        log.error("Reading #{path} failed with exception: #{error.inspect}")
        nil
      end
    end
  end
end
