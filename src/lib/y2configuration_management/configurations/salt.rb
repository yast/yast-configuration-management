require "y2configuration_management/configurations/base"
require "y2configuration_management/configurations/formulas_set"
require "pathname"

module Y2ConfigurationManagement
  module Configurations
    # This class represents the module's configuration when using Salt.
    #
    # It extends the {Base} class with some Salt specific options. See #post_initialize for further
    # information about those options.
    #
    # The methods that are related to path names ({#states_root}, {#formulas_roots}, {#pillar_root},
    # {#pillar_roots}, are aware of the scope where YaST is running, so it takes
    # `Yast::Installation.destdir` into account.
    #
    # @example Directories during installation
    #   config = Salt.new
    #   config.pillar_roots #=> [#<Pathname:/mnt/var/lib/YaST2/cm-202005120829/pillar>]
    #   config.pillar_roots(:target) #=> [#<Pathname:/var/lib/YaST2/cm-202005120829/pillar>]
    class Salt < Base
      # @return [URI,nil] Location of Salt states
      attr_reader :states_url
      # @return [URI,nil] Location of Salt pillars
      attr_reader :pillar_url
      # @return [Array<String>] States (including formulas) which will be applied
      attr_reader :enabled_states
      # @return [Array<FormulasSet>] List of formulas locations
      attr_reader :formulas_sets

      class << self
        # Returns a {Salt} object from a hash
        #
        # @todo Consider moving this logic elsewhere. Dealing with the import process looks like too
        #   much for this class.
        #
        # @param hash [Hash] Hash containing the options
        # @return [Salt] Salt configuration instance
        def new_from_hash(hash)
          options = Hash[hash.map { |k, v| [k.to_sym, v] }]
          options[:formulas_sets] = options.fetch(:formulas_sets, []).map do |hsh|
            FormulasSet.new(hsh["metadata_root"], hsh["states_root"], hsh["pillar_root"])
          end

          # Support for :formulas_roots option for backward compatibility reasons
          if options[:formulas_roots]
            sets = options[:formulas_roots].map { |path| FormulasSet.new(path) }
            options[:formulas_sets].concat(sets)
            options.delete(:formulas_roots)
          end

          new(options)
        end
      end

      # Custom initialization code
      #
      # @param options [Hash<Symbol,Object>] Constructor options
      # @option options [String] :states_url URL of the states tarball
      # @option options [String] :pillar_url URL of the pillar data tarball
      # @option options [String,Pathname] :pillar_root Path to the pillar data directory
      # @option options [Array<String,Pathname>] :states_roots Path to the states directories
      # @option options [Array<String>] :enabled_states List of enabled Salt states
      # @option options [Array<Hash<String,String>>] :formulas_sets Formulas locations
      def post_initialize(options)
        @type = "salt"
        @states_url = URI(options[:states_url]) if options[:states_url]
        @pillar_url = URI(options[:pillar_url]) if options[:pillar_url]
        @custom_pillar_root = Pathname.new(options[:pillar_root]) if options[:pillar_root]
        @custom_states_roots = pathnames_from(options[:states_roots])
        @enabled_states = options.fetch(:enabled_states, [])
        @formulas_sets = options.fetch(:formulas_sets, [])
      end

      # Return path to the Salt main pillars directory (the one containing the top.sls)
      #
      # @param scope [Symbol] Path relative to inst-sys (:local) or the
      #   target system (:target)
      # @return [Array<Pathname>] Path to Salt pillars
      def pillar_roots(scope = :local)
        paths = ([@custom_pillar_root] + formulas_sets.map(&:pillar_root)).compact
        paths = scoped_paths(paths, scope)
        paths.unshift(default_pillar_root(scope)) unless @custom_pillar_root
        paths
      end

      # Return path to the default Salt pillars directory
      #
      # If it is not defined by the user, the default pillar directory lives
      # under the {#work_dir}.
      #
      # @param scope [Symbol] Path relative to inst-sys (:local) or the
      #   target system (:target)
      # @return [Pathname] Path to Salt pillars
      def default_pillar_root(scope = :local)
        work_dir(scope).join("pillar")
      end

      # Return paths to the states root
      #
      # @param scope [Symbol] Path relative to inst-sys (:local) or the
      #   target system (:target)
      # @return [Array<Pathname>] Path to Salt state roots
      def states_roots(scope = :local)
        paths = @custom_states_roots + formulas_sets.map(&:states_root).compact
        [default_states_root(scope)] + scoped_paths(paths, scope)
      end

      # Return path to the default Salt states directory
      #
      # The default Salt states directory lives under the {#work_dir}.
      #
      # @param scope [Symbol] Path relative to inst-sys (:local) or the
      #   target system (:target)
      # @return [Pathname] Path to Salt states
      def default_states_root(scope = :local)
        work_dir(scope).join("salt")
      end

      # Return paths to all formulas directories
      #
      # @param scope [Symbol] Path relative to inst-sys (:local) or the
      #   target system (:target)
      # @return [Array<Pathname>] Path to Salt formulas roots
      def formulas_roots(scope = :local)
        paths = formulas_sets.map(&:metadata_root).compact
        scoped_paths(paths, scope) + [default_formulas_root(scope)]
      end

      # Return path to the default Salt formulas directory
      #
      #
      # @param scope [Symbol] Path relative to inst-sys (:local) or the
      #   target system (:target)
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
