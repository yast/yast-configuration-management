require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/matcher"

module Yast
  module SCM
    module CFA
      # Represents a Puppet configuration file.
      class Puppet < ::CFA::BaseModel
        # Configuration parser
        PARSER = ::CFA::AugeasParser.new("puppet.lns")
        # Path to configuration file
        PATH = "/etc/puppet/puppet.conf".freeze

        # Constructor
        #
        # @param file_handler [.read, .write, nil] an object able to read/write a string.
        def initialize(file_handler: nil)
          super(PARSER, PATH, file_handler: file_handler)
        end

        # Set server name
        #
        # @param name [String] Puppet master server's name
        # @return [String] Puppet master server's name
        def server=(name)
          data["main"]["server"] = name
        end

        # Return server name
        #
        # @return [String] Puppet master server's name
        def server
          data["main"]["server"]
        end
      end
    end
  end
end
