require "yast"
require "installation/auto_client"
require "y2configuration_management/configurators/base"
require "y2configuration_management/configurations/base"
require "pathname"

Yast.import "PackagesProposal"

module Y2ConfigurationManagement
  # AutoClient implementation
  #
  # This module takes care of importing and configuring the configuration management module so the
  # {ConfigurationManagementFinish} can provision the system at the end of the installation.
  #
  # It takes care of:
  #
  # * Importing the configuration (see {Configurations::Base.import}).
  # * Initializing the configurator (see {Configurators::Base.for}).
  # * Adding the required packages to the list of packages to install.
  #
  # It might change in the future but at this point in time this client only uses the information
  # specified in the AutoYaST profile. For instance, when using Salt, it does not consider the
  # formulas installed via RPM packages in the target system.
  #
  # @see Configurations
  # @see Configurators
  class AutoClient < ::Installation::AutoClient
    include Yast::I18n

    # Import AutoYaST configuration
    #
    # Additional configurator-specific options can be specified. They will be passed to the
    # configurator's constructor.
    #
    # @param profile [Hash] Options from an AutoYaST profile
    # @option profile [String] "type"            Configurator to use ("salt", "puppet", etc.)
    # @option profile [String] "master"          Master server name
    # @option profile [String] "auth_attempts"   Number of authentication attempts
    # @option profile [String] "auth_time_out"   Authentication time out for each
    #                                            authentication attempt
    # @option profile [String] "states_url"      Location of Salt states
    # @option profile [String] "modules_url"     Location of Puppet modules
    # @option profile [String] "keys_url"        Authentication keys URL
    # @return [Hash] configuration from AutoYaST profile
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

    # Determines whether the profile data has been modified
    #
    # This method always returns `false` because no information from this module is included in the
    # cloned profile.
    #
    # @return [true]
    def modified?
      false
    end

    # Sets the profile as modified
    #
    # This method does not perform any modification because no information from this module is
    # included in the cloned profile.
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
