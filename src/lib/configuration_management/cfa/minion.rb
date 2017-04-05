require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/matcher"

module Yast
  module ConfigurationManagement
    module CFA
      # Represents a Salt Minion configuration file.
      class Minion < ::CFA::BaseModel
        attributes(master: "master")

        # Configuration parser
        # FIXME: At this time, we're using Augeas' cobblersettings lense,
        # as long as YAML is not supported. We should use another parser.
        PARSER = ::CFA::AugeasParser.new("cobblersettings.lns")
        # Path to configuration file
        PATH = "/etc/salt/minion".freeze

        # Constructor
        #
        # @param file_handler [.read, .write, nil] an object able to read/write a string.
        def initialize(file_handler: nil)
          super(PARSER, PATH, file_handler: file_handler)
        end

        def master=(master_name)
          # FIXME: the cobblersettings lense does not support dashes in the value
          # without single quotes, we need to use a custom lense for salt conf.
          # As Salt can use also 'master' just use in case of dashed.
          data["master"] = master_name.include?("-") ? "'#{master_name}'" : master_name
        end
      end
    end
  end
end
