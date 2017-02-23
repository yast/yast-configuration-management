require "cm/configurations/base"

module Yast
  module CM
    module Configurations
      # This class represents the module's configuration when
      # using Salt.
      #
      # It extends the Configurations::Base class with some
      # custom attributes (@see #states_url).
      class Salt < Base
        # @return [URI,nil] Location of Salt states
        attr_reader :states_url

        # Custom initialization code
        #
        # @return options [Hash] Constructor options
        def post_initialize(options)
          @type       = "salt"
          @states_url = URI(options[:states_url]) if options[:states_url]
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
