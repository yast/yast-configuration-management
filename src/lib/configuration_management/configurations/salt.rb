require "configuration_management/configurations/base"
require "pathname"

module Yast
  module ConfigurationManagement
    module Configurations
      # This class represents the module's configuration when
      # using Salt.
      #
      # It extends the Configurations::Base class with some
      # custom attributes (@see #states_url and #pillar_url).
      class Salt < Base
        # @return [URI,nil] Location of Salt states
        attr_reader :states_url
        # @return [URI,nil] Location of Salt pillars
        attr_reader :pillar_url

        # Custom initialization code
        #
        # @param options [Hash] Constructor options
        def post_initialize(options)
          @type       = "salt"
          @states_url = URI(options[:states_url]) if options[:states_url]
          @pillar_url = URI(options[:pillar_url]) if options[:pillar_url]
          @custom_pillar_root = pathnames_from(options[:pillar_root])
          @custom_states_roots = pathnames_from(options[:states_roots])
          @custom_formulas_roots = pathnames_from(options[:formulas_roots])
        end

        # Return path to the Salt states directory
        #
        # @return [Pathname] Path to Salt states
        def states_root(scope = :local)
          work_dir(scope).join("salt")
        end

        # Return path to the Salt pillar directory
        #
        # @return [Pathname] Path to Salt pillars
        def pillar_root(scope = :local)
          return scoped_paths(@custom_pillar_root, scope) if @custom_pillar_root.first
          work_dir(scope).join("pillar")
        end

        # Return path to the Salt pillar directory
        #
        # @return [Pathname] Path to Salt pillars
        def formulas_root(scope = :local)
          work_dir(scope).join("formulas")
        end

        # Return paths to the states root
        def states_roots(scope = :local)
          scoped_paths(@custom_states_roots, scope) + [states_root(scope)]
        end

        # Return paths to the fromulas root
        def formulas_roots(scope = :local)
          scoped_paths(@custom_formulas_roots) + [formulas_root(scope)]
        end

      private

        def scoped_paths(paths, scope = :local)
          return paths if scope == :target
          prefix = Pathname.new(Installation.destdir)
          paths.map { |d| prefix.join(d) }
        end

        def pathnames_from(dirs)
          return [] unless dirs.is_a?(Array)
          dirs.map { |d| Pathname.new(d) }
        end
      end
    end
  end
end
