require "cm/configurations/base"

module Yast
  module CM
    module Configurations
      # This class inteprets the module configuration
      class Puppet < Base
        # @return [URI,nil] System definition URL (states, recipes, etc.)
        attr_reader :modules_url

        # Constructor
        def post_initialize(options)
          @type        = "puppet"
          @modules_url = options[:modules_url]
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
