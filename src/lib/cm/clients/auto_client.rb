require "yast"
require "installation/auto_client"
require "cm/provisioner"
require "cm/dialogs/running"

module Yast
  module CM
    # AutoClient implementation
    #
    # The real work is delegated to Provisioners.
    #
    # @see Yast::CM::Provisioner
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
      # @option profile [String] "type"     Provisioner to use ("salt", "puppet", etc.)
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
        dialog = Yast::CM::Dialogs::Running.new
        dialog.run do |stdout, stderr|
          # Connect stdout and stderr with the dialog
          Provisioner.current.run(stdout, stderr)
        end
        true
      end
    end
  end
end
