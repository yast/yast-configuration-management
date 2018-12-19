require "configuration_management/configurations/base"
require "pathname"

module Yast
  module ConfigurationManagement
    module Configurations
      # This class represents the module's configuration when
      # using Salt.
      #
      # It extends the Configurations::Base class with some
      # custom attributes (see {#states_url} and {#pillar_url}).
      class Salt < Base
        # @return [URI,nil] Location of Salt states
        attr_reader :states_url
        # @return [URI,nil] Location of Salt pillars
        attr_reader :pillar_url
        # @return [Array<String>] States (including formulas) which will be applied
        attr_reader :enabled_states

        # Custom initialization code
        #
        # @param options [Hash] Constructor options
        def post_initialize(options)
          @type       = "salt"
          @states_url = URI(options[:states_url]) if options[:states_url]
          @pillar_url = URI(options[:pillar_url]) if options[:pillar_url]
          @custom_pillar_root = Pathname(options[:pillar_root]) if options[:pillar_root]
          @custom_states_roots = pathnames_from(options[:states_roots])
          @custom_formulas_roots = pathnames_from(options[:formulas_roots])
          @enabled_states = options.fetch(:enabled_states, [])
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
          return scoped_paths([@custom_pillar_root], scope).first if @custom_pillar_root
          work_dir(scope).join("pillar")
        end

        # Return path to the Salt pillar directory
        #
        # @return [Pathname] Path to Salt pillars
        def formulas_root(scope = :local)
          work_dir(scope).join("formulas")
        end

        # Return paths to the states root
        #
        # @return [Array<Pathname>] Path to Salt state roots
        def states_roots(scope = :local)
          [states_root(scope)] + scoped_paths(@custom_states_roots, scope)
        end

        # Return paths to the fromulas root
        #
        # @return [Array<Pathname>] Path to Salt formulas roots
        def formulas_roots(scope = :local)
          [formulas_root(scope)] + scoped_paths(@custom_formulas_roots)
        end

      private

        # Convenience method for obtaining the list of given paths relative to
        # inst-sys (scope: :local) or to the target system (scope: :target)
        #
        # @param paths [Array<Pathname>] list of path to be scoped
        # @param scope [Symbol] Path relative to inst-sys (:local) or the
        #   target system (:target)
        # @return [Array<Pathname>] list of the given paths prefixed by the
        #   destination directory in case of :local scope
        def scoped_paths(paths, scope = :local)
          return paths if scope == :target
          prefix = Pathname.new(Installation.destdir)
          paths.map { |d| prefix.join(d) }
        end

        # Convenience method for converting from a list of directory names to a
        # list of {Pathname}s
        #
        # @param dirs [Array<String>] list of directory names
        # @return [Array<Pathname>]
        def pathnames_from(dirs)
          return [] unless dirs.is_a?(Array)
          dirs.map { |d| Pathname.new(d) }
        end
      end
    end
  end
end
