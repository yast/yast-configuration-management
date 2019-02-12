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
require "date"
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

      # @return [Pathname] Pillar file path
      attr_accessor :path

      # Constructor
      #
      # @param data [Hash] The pillar data (deserialized pillar_name.yml).
      # @param path [Pathname] pillar file path
      def initialize(data: {}, path: nil)
        @data = data
        @path = path
      end

      # Creates a new {Pillar} object reading its data from a YAML file
      #
      # @param path [Pathname] file path to read the form YAML definition
      # @return [Pillar, nil]
      def self.from_file(path)
        pillar = new(data: {}, path: path)
        pillar.load ? pillar : nil
      end

      # Loads the pillar data from its pillar file
      #
      # @return [Boolean] whether the configuration was read
      def load
        return false unless path
        @data = YAML.safe_load(File.read(path), [Date, Time])
        true
      rescue IOError, SystemCallError, RuntimeError => error
        log.error("Reading #{path} failed with exception: #{error.inspect}")
        false
      end

      # Write the pillar data to its file
      #
      # @return [Boolean] whether the pillar was written or not
      def save
        return false unless path

        pillar_dir = File.dirname(path)
        FileUtils.mkdir_p(pillar_dir) unless File.exist?(pillar_dir)
        log.info("Writing #{path} with data: #{data.inspect}")
        File.open(path, "w+") { |f| f.puts YAML.dump(data) }
        true
      rescue IOError, SystemCallError, RuntimeError => error
        log.error("Writing #{path} failed with exception: #{error.inspect}")
        false
      end

      # Does a YAML dump of the pillar data
      def dump
        YAML.dump(data)
      end
    end
  end
end
