require "yast"
require "installation/auto_client"
require "configuration_management/configurators/base"
require "configuration_management/configurations/base"
require "pathname"

Yast.import "PackagesProposal"

module Yast
  module ConfigurationManagement
    # AutoClient implementation
    #
    # The real work is delegated to Configurators.
    #
    # @see Yast::ConfigurationManagement::Configurators
    class AutoClient < ::Installation::AutoClient
      include Yast::I18n

      # Import AutoYaST configuration
      #
      # Additional configurator-specific options can be specified. They will be passed
      # to the configurator's constructor.
      #
      # @return profile [Hash] configuration from AutoYaST profile
      # @option profile [String] "type"            Configurator to use ("salt", "puppet", etc.)
      # @option profile [String] "master"          Master server name
      # @option profile [String] "auth_attempts"   Number of authentication attempts
      # @option profile [String] "auth_time_out"   Authentication time out for each
      #                                            authentication attempt
      # @option profile [String] "states_url"      Location of Salt states
      # @option profile [String] "modules_url"     Location of Puppet modules
      # @option profile [String] "keys_url"        Authentication keys URL
      def import(profile = {})
        Configurations::Base.import(profile)
        self.configurator = Configurators::Base.for(Configurations::Base.current)

        # Added needed packages for writing the configuration
        Yast::PackagesProposal.AddResolvables("yast2-configuration-management",
          :package, packages["install"])

        true
      end

      # Return packages to install
      #
      # @see Configurators::Base#packages
      def packages
        configurator.nil? ? [] : configurator.packages
      end

      # Apply the configuration running the configurator
      #
      # @see Configurators::Base#current
      def write
        configurator.prepare if configurator
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

    private

      # Convenience helper method to get the current configurator
      #
      # @return [Configurators::Base] Configurator to use
      #
      # @see Configurators::Base.current
      def configurator
        Configurators::Base.current
      end

      # Convenience helper method to set the current configurator
      #
      # @param value [Configurators::Base] Configurator to use
      #
      # @see Configurators::Base.current=
      def configurator=(value)
        Configurators::Base.current = value
      end
    end
  end
end
