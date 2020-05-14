require "y2configuration_management/configurations/base"
require "pathname"

module Y2ConfigurationManagement
  module Configurations
    # This class represents the module's configuration when using Salt.
    #
    # It extends the {Base} class with some Salt specific options. See #post_initialize for further
    # information about those options.
    class Salt < Base
      # @return [URI,nil] Location of Salt states
      attr_reader :states_url
      # @return [URI,nil] Location of Salt pillars
      attr_reader :pillar_url
      # @return [Array<String>] States (including formulas) which will be applied
      attr_reader :enabled_states

      # Custom initialization code
      #
      # @param options [Hash<Symbol,Object>] Constructor options
      # @option options [String] :states_url URL of the states tarball
      # @option options [String] :pillar_url URL of the pillar data tarball
      # @option options [String,Pathname] :pillar_root Path to the pillar data directory
      # @option options [Array<String,Pathname>] :states_roots Path to the states directories
      # @option options [Array<String,Pathname>] :formulas_roots Path to the formulas directories
      # @option options [Array<String>] :enabled_states List of enabled Salt states
      def post_initialize(options)
        @type = "salt"
        @states_url = URI(options[:states_url]) if options[:states_url]
        @pillar_url = URI(options[:pillar_url]) if options[:pillar_url]
        @custom_pillar_root = Pathname(options[:pillar_root]) if options[:pillar_root]
        @custom_states_roots = pathnames_from(options[:states_roots])
        @custom_formulas_roots = pathnames_from(options[:formulas_roots])
        @enabled_states = options.fetch(:enabled_states, [])
      end

      # Return path to the Salt pillars directory
      #
      # It takes the `Yast::Installation.destdir` so, when it is different from
      # "/", you can use the `scope` argument to tell if you want to get the
      # :local or the :target path.
      #
      # @example Default pillars directory
      #   config = Salt.new
      #   config.pillar_root #=> #<Pathname:/var/lib/YaST2/cm-202005120829/pillar>
      #
      # @example Default pillars directory during installation
      #   config = Salt.new
      #   config.pillar_root #=> #<Pathname:/mnt/var/lib/YaST2/cm-202005120829/pillar>
      #
      # @example Default pillars directory in :target system during installation
      #   config = Salt.new
      #   config.pillar_root(:target) #=> #<Pathname:/var/lib/YaST2/cm-202005120829/pillar>
      #
      # @example Using a custom pillar directory
      #   config = Salt.new(pillar_root: "/srv/salt/custom_pillar")
      #   config.pillar_root #=> #<Pathname:/srv/salt/custom_pillar>
      #
      # @return [Pathname] Path to Salt pillars
      def pillar_root(scope = :local)
        return scoped_paths([@custom_pillar_root], scope).first if @custom_pillar_root
        work_dir(scope).join("pillar")
      end

      # Return paths to the states root
      #
      # It takes the `Yast::Installation.destdir so, when it is different from
      # "/", you can use the `scope` argument to tell if you want to get the
      # :local or the :target path.
      #
      # @example Default states roots
      #   config = Salt.new({})
      #   config.states_roots #=> [#<Pathname:/var/lib/YaST2/cm-202005120908/salt>]
      #
      # @example Default states roots during installation
      #   config = Salt.new
      #   config.states_root #=> [#<Pathname:/mnt/var/lib/YaST2/cm-202005120908/salt>]
      #
      # @example Default states roots in :target system during installation
      #   config = Salt.new
      #   config.states_root(:target) #=> [#<Pathname:/var/lib/YaST2/cm-202005120908/salt>]
      #
      # @example Custom states roots
      #   config = Salt.new(states_roots: ["/srv/custom"])
      #   config.states_roots #=> [#<Pathname:/srv/custom>,
      #     #<Pathname:/var/lib/YaST2/cm-202005120908/salt>]
      #
      # @return [Array<Pathname>] Path to Salt state roots
      def states_roots(scope = :local)
        scoped_paths(@custom_states_roots, scope) + [states_root(scope)]
      end

      # Return path to the Salt states directory
      #
      # @return [Pathname] Path to Salt states
      def states_root(scope = :local)
        work_dir(scope).join("salt")
      end

      # Return paths to all formulas directories
      #
      # @return [Array<Pathname>] Path to Salt formulas roots
      def formulas_roots(scope = :local)
        scoped_paths(@custom_formulas_roots) + [default_formulas_root(scope)]
      end

      # Return path to the default Salt formulas directory
      #
      # @example Default formulas directory
      #   config = Salt.new
      #   config.formulas_root #=> #<Pathname:/var/lib/YaST2/cm-202005120836/formulas>
      #
      # @example Default formulas directory during installation
      #   config = Salt.new
      #   config.formulas_root #=> #<Pathname:/mnt/var/lib/YaST2/cm-202005120836/formulas>
      #
      # @example Default formulas directory in :target system during installation
      #   config = Salt.new(scope: :target)
      #   config.formulas_root #=> #<Pathname:/var/lib/YaST2/cm-202005120836/formulas>
      #
      # @example Custom states roots
      #   config = Salt.new(formulas_roots: ["/srv/custom"])
      #   config.formulas_roots #=> [#<Pathname:/srv/custom>,
      #     #<Pathname:/var/lib/YaST2/cm-202005120908/formulas>]
      #
      # @return [Pathname] Path to Salt formulas
      def default_formulas_root(scope = :local)
        work_dir(scope).join("formulas")
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
        prefix = Pathname.new(Yast::Installation.destdir)
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
