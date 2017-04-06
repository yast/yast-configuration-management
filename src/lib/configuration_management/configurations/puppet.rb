require "configuration_management/configurations/base"

module Yast
  module ConfigurationManagement
    module Configurations
      # This class represents the module's configuration when
      # using Puppet.
      #
      # It extends the Configurations::Base class with some
      # custom attributes (@see #modules_url).
      class Puppet < Base
        # @return [URI,nil] Location of Puppet modules
        attr_reader :modules_url

        # Custom initialization code
        #
        # @return options [Hash] Constructor options
        def post_initialize(options)
          @type        = "puppet"
          @modules_url = URI(options[:modules_url]) if options[:modules_url]
        end

        # Return an array of exportable attributes
        #
        # @return [Array<Symbol>] Attribute names
        def attributes
          @attributes ||= super + [:modules_url]
        end
      end
    end
  end
end
