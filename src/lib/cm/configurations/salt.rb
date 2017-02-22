require "cm/configurations/base"

module Yast
  module CM
    module Configurations
      # This class inteprets the module configuration
      class Salt < Base
        # @return [URI,nil] System definition URL (states, recipes, etc.)
        attr_reader :states_url

        # Constructor
        def post_initialize(options)
          @type       = "salt"
          @states_url = options[:states_url]
        end

        # Return an array of exportable attributes
        #
        # @return [Array<Symbol>] Attribute names
        def attributes
          @attributes ||= super + [:states_url]
        end
      end
    end
  end
end
