require "yast"
require "installation/auto_client"
require "cm/configurators/base"
require "cm/dialogs/running"

module Yast
  module CM
    # AutoClient implementation
    #
    # The real work is delegated to Configurators.
    #
    # @see Yast::CM::Configurators
    class AutoClient < ::Installation::AutoClient
      include Yast::I18n

      # Constructor
      def initialize
        Yast.import "Popup"
      end

      # Import AutoYaST configuration
      #
      # Additional configurator-specific options can be specified. They will be passed
      # to the configurator's constructor.
      #
      # @return profile [Hash] configuration from AutoYaST profile
      # @option profile [String] "type"     Configurator to use ("salt", "puppet", etc.)
      # @option profile [String] "master"   Master server name
      # @option profile [String] "timeout"  Authentication timeout
      # @option profile [String] "attempts" Authentication retries
      def import(profile = {})
        config = {}
        profile.each_with_object(config) do |option, cfg|
          key = option[0].to_sym
          val = option[1]
          cfg[key] = val unless key == :type
        end

        type = profile["type"].nil? ? "salt" : profile["type"].downcase
        Configurators::Base.current = Configurators::Base.configurator_for(type, config)
        true
      end

      # Return packages to install
      #
      # @see Configurators::Base#packages
      def packages
        Configurators::Base.current.packages
      end

      # Apply the configuration running the configurator
      #
      # @see Configurators::Base#current
      def write
        dialog = Yast::CM::Dialogs::Running.new
        dialog.run do |stdout, stderr|
          # Connect stdout and stderr with the dialog
          Configurators::Base.current.run(stdout, stderr)
        end
        true
      end

      # Determines whether the profile data has been modified
      #
      # This method always returns `false` because no information from this
      # module is included in the cloned profile.
      #
      # @return [true]
      def modified?
        false
      end

      # Sets the profile as modified
      #
      # This method does not perform any modification because no information
      # from this module is included in the cloned profile.
      #
      # @return [true]
      def modified
        false
      end

      # Data to include in the cloned profile
      #
      # No information from this module in included in the cloned profile.
      #
      # @return [{}] Returns an empty Hash
      def export
        {}
      end
    end
  end
end
