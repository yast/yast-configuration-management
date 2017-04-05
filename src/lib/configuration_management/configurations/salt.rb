require "cm/configurations/base"

module Yast
  module ConfigurationManagement
    module Configurations
      # This class represents the module's configuration when
      # using Salt.
      #
      # It extends the Configurations::Base class with some
      # custom attributes (@see #states_url).
      class Salt < Base
        # @return [URI,nil] Location of Salt states
        attr_reader :states_url
        # @return [URI,nil] Location of Salt pillars
        attr_reader :pillar_url

        # Custom initialization code
        #
        # @return options [Hash] Constructor options
        def post_initialize(options)
          @type       = "salt"
          @states_url = URI(options[:states_url]) if options[:states_url]
          @pillar_url = URI(options[:pillar_url]) if options[:pillar_url]
        end

        # Return an array of exportable attributes
        #
        # @return [Array<Symbol>] Attribute names
        def attributes
          @attributes ||= super + [:states_url, :pillar_url]
        end

        # Return path to the Salt states directory
        #
        # @return [Pathname] Path to Salt states
        def states_root
          work_dir.join("salt")
        end

        # Return path to the Salt pillar directory
        #
        # @return [Pathname] Path to Salt pillars
        def pillar_root
          work_dir.join("pillar")
        end

        # Return path to the Salt pillar directory
        #
        # @return [Pathname] Path to Salt pillars
        def formulas_root
          work_dir.join("formulas")
        end
      end
    end
  end
end
