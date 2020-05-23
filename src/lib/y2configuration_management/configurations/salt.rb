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
        @custom_formulas_sets = options.fetch(:formulas_sets, [])
      end

      # Return path to the Salt main pillars directory (the one containing the top.sls)
      #
      # @return [Array<Pathname>] Path to Salt pillars
      def pillar_roots
        paths = ([@custom_pillar_root] + formulas_sets.map(&:pillar_root)).compact
        paths.unshift(default_pillar_root) unless @custom_pillar_root
        paths
      end

      # Return path to the default Salt pillars directory
      #
      # If it is not defined by the user, the default pillar directory lives
      # under the {#work_dir}.
      #
      # @return [Pathname] Path to Salt pillars
      def default_pillar_root
        work_dir.join("pillar")
      end

      # Return paths to the states root
      #
      # @return [Array<Pathname>] Path to Salt state roots
      def states_roots
        paths = @custom_states_roots + formulas_sets.map(&:states_root).compact
        [default_states_root] + paths
      end

      # Return path to the default Salt states directory
      #
      # The default Salt states directory lives under the {#work_dir}.
      #
      # @return [Pathname] Path to Salt states
      def default_states_root
        work_dir.join("salt")
      end

      # TODO: is still used?
      # Return paths to all formulas directories
      #
      # @return [Array<Pathname>] Path to Salt formulas roots
      def formulas_roots
        formulas_sets.map(&:metadata_root).compact
      end

      # Return the list of formulas sets
      #
      # @return [Array<FormulasSet>] List of formulas sets
      def formulas_sets
        [default_formulas_set] + @custom_formulas_sets
      end

    private

      # Return path to the default Salt formulas directory
      #
      # @return [Pathname] Path to Salt formulas
      def default_formulas_set
        @default_formula_set ||= FormulasSet.from_directory(work_dir.join("formulas"))
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
