require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/matcher"

module Yast
  module CM
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

        # Update attributes
        #
        # @param attrs [Hash] Attributes in key-value form
        def update(attrs = {})
          attrs.each do |key, value|
            meth = "#{key}="
            send(meth, value) if respond_to?(meth)
          end
        end

        # Set auth_timeout value
        #
        # @param value [Fixnum,nil] auth_timeout value or nil to unset it
        # @return [Fixnum,nil] Assigned value
        def auth_timeout=(value)
          data["auth_timeout"] = value ? value.to_s : value
          auth_timeout
        end

        # Returns the auth_timeout value
        #
        # @return value [Fixnum,nil] auth_timeout value or nil if not set
        def auth_timeout
          data["auth_timeout"].to_i if data["auth_timeout"]
        end

        # Set auth_tries value
        #
        # @param value [Fixnum,nil] auth_tries value or nil to unset it
        # @return [Fixnum,nil] Assigned value
        def auth_tries=(value)
          data["auth_tries"] = value ? value.to_s : value
          auth_tries
        end

        # Returns the auth_tries value
        #
        # @return value [Fixnum,nil] auth_tries value or nil if not set
        def auth_tries
          data["auth_tries"].to_i if data["auth_tries"]
        end
      end
    end
  end
end
