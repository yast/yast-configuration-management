require "yast"
require "installation/auto_client"
require "scm/provisioner"

module Yast
  module SCM
    # AutoClient implementation
    #
    # The real work is delegated to Provisioners.
    #
    # @see Yast::SCM::Provisioner
    class AutoClient < ::Installation::AutoClient
      include Yast::I18n

      # Constructor
      def initialize
        Yast.import "Popup"
      end

      # Import AutoYaST configuration
      #
      # Additional provisioner-specific options can be specified. They will be passed
      # to the provisioner's constructor.
      #
      # @return profile [Hash] configuration from AutoYaST profile
      # @option profile [String] "type"         Provisioner to use ("salt", "puppet", etc.)
      # @option profile [String] "master"       Master server name
      # @option profile [String] "auth_timeout" Authentication timeout
      # @option profile [String] "auth_retries" Authentication retries
      def import(profile = {})
        config = {}
        profile.each_with_object(config) do |option, cfg|
          key = option[0].to_sym
          val = option[1]
          cfg[key] = val unless key == :type
        end

        type = profile["type"].nil? ? "salt" : profile["type"].downcase
        Provisioner.current = Provisioner.provisioner_for(type, config)
        true
      end

      # Return packages to install
      #
      # @see Provisioner#packages
      def packages
        Provisioner.current.packages
      end

      # Apply the configuration running the provisioner
      #
      # @see Provisioner#current
      def write
        Popup.Feedback(_("Running provisioner"), _("Please wait...")) do
          Provisioner.current.run
        end
        true
      end
    end
  end
end
