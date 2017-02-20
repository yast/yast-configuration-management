require "yast"
require "pathname"

module Yast
  module CM
    module Runners
      class Base
        include Yast::Logger

        # FIXME: duplicated in configurators/base.rb
        MODES = [:masterless, :client].freeze

        # @return [String,nil] Master server hostname
        attr_reader :master
        # @return [Integer] Number of authentication retries
        attr_reader :attempts
        # @return [Integer] Authentication timeout for each retry
        attr_reader :timeout
        # @return [Symbol] Mode. Possible values are listed in MODE constant.
        attr_reader :mode
        # @return [Pathname] Directory where the configuration lives.
        attr_reader :config_dir

        class << self
          # Return the configurator class to handle a given CM system
          #
          # It tries to find the definition.
          #
          # @param type [String] CM type ("salt", "puppet", etc.)
          # @return [Class] Runner class
          def runner_class(type)
            require "cm/runners/#{type}"
            Yast::CM::Runners.const_get type.capitalize
          rescue NameError, LoadError
            raise "Runner for '#{type}' not found"
          end
        end

        # Constructor
        #
        # @param config [Hash] config
        # @option config [Integer] :mode     Operation's mode
        # @option config [Integer] :attempts Number of authentication retries
        # @option config [Integer] :timeout  Authentication timeout for each retry
        def initialize(config = {})
          log.info "Initializing runner #{self.class.name} with #{config}"
          @master     = config[:master]
          @attempts   = config[:attempts]
          @timeout    = config[:timeout]
          @mode       = config[:mode]
          @config_dir = Pathname.new(config[:config_dir]) unless config[:config_dir].nil?
        end

        # Run the configurator applying the configuration to the system
        #
        # Work is delegated to methods called after the mode: #run_masterless_mode
        # and #run_client_mode.
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @see run_masterless_mode
        # @see run_client_mode
        def run(stdout = nil, stderr = nil)
          stdout ||= $stdout
          stderr ||= $stderr
          case mode
          when :client
            with_retries(attempts) { |i| run_client_mode(stdout, stderr, i) }
          when :masterless
            run_masterless_mode(stdout, stderr)
          end
        end

      protected

        # Apply the configuration using the CM system
        #
        # To be redefined by inheriting classes.
        #
        # @param stdout  [IO]     Standard output channel used by the configurator
        # @param stderr  [IO]     Standard error channel used by the configurator
        # @param attempt [Fixnum] Attempt number
        #
        # @return [Boolean] true if the configuration was applied; false otherwise.
        def run_client_mode(_stdout, _stderr, _attempt)
          raise NotImplementedError
        end

        # Apply the configuration using the CM system
        #
        # Configuration is available at #config_tmpdir
        #
        # @param stdout  [IO]     Standard output channel used by the configurator
        # @param stderr  [IO]     Standard error channel used by the configurator
        #
        # @return [Boolean] true if the configuration was applied; false otherwise.
        #
        # @see config_tmpdir
        def run_masterless_mode(_stdout, _stderr)
          raise NotImplementedError
        end

        def with_retries(attempts = 1)
          attempts.times do |i|
            log.info "Running provisioner (try #{i + 1}/#{attempts})"
            return true if yield(i)
          end
          false
        end
      end
    end
  end
end
