require "y2configuration_management/configurations/base"

module Y2ConfigurationManagement
  module Configurations
    # This class represents the module's configuration when using Puppet.
    #
    # It extends the Configurations::Base class with some Puppet specific options.
    # See #post_initialize for further information about those options.
    class Puppet < Base
      # @return [URI,nil] Location of Puppet modules
      attr_reader :modules_url

      # Custom initialization code
      #
      # @param options [Hash<Symbol,Object>] Constructor options
      # @option options [URI,String,nil] :modules_url URL to get the modules from
      #   Ignored when running in :client mode.
      #
      # @raise URI::InvalidURIError
      def post_initialize(options)
        @type = "puppet"
        @modules_url = URI(options[:modules_url]) if options[:modules_url]
      end
    end
  end
end
