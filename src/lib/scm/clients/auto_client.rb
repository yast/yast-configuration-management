require "yast"
require "installation/auto_client"
require "scm/provisioner"

module Yast
  module SCM
    class AutoClient < ::Installation::AutoClient
      include Yast::I18n

      # Constructor
      def initialize
        Yast.import "Popup"
      end

      # Import AutoYaST configuration
      def import(data)
        config = {}
        data.each_with_object(config) do |option, cfg|
          key = option[0].to_sym
          val = option[1]
          cfg[key] = val unless key == :type
        end

        Provisioner.current = Provisioner.new(data["type"].downcase, data)
        true
      end

      # Return packages to install
      def packages
        provisioner.packages
      end

      # Apply the configuration running the provisioner
      def write
        Popup.Feedback(_("Running provisioner"), _("Please wait...")) do
          provisioner.run
        end
        true
      end

      # Helper method to get the current provisioner
      def provisioner
        log.info "Provisioner #{Provisioner.current.class}"
        Provisioner.current
      end
    end
  end
end
