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
        attr_reader :auth_attempts
        # @return [Integer] Authentication time out for each attempt
        attr_reader :auth_time_out
        # @return [Symbol] Mode. Possible values are listed in MODE constant.
        attr_reader :mode
        # @return [Pathname] Directory where the configuration lives.
        attr_reader :definitions_root

        class << self
          # Return the runner for a given CM system and a configuration
          def runner_for(config)
            runner_class(config.type).new(config.to_hash)
          end

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
        # @option config [Integer] :mode          Operation's mode
        # @option config [Integer] :auth_attempts Number of authentication attempts
        # @option config [Integer] :auth_time_out Authentication time out for each attempt
        def initialize(config = {})
          log.info "Initializing runner #{self.class.name} with #{config}"
          @master           = config[:master]
          @auth_attempts    = config[:auth_attempts]
          @auth_time_out    = config[:auth_time_out]
          @mode             = config[:mode]
          @definitions_root = Pathname.new(config[:definitions_root]) unless config[:definitions_root].nil?
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
          send("run_#{mode}_mode", stdout, stderr)
        end

      protected

        # Apply the configuration using the CM system
        #
        # To be redefined by inheriting classes.
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @return [Boolean] true if the configuration was applied; false otherwise.
        def run_client_mode(_stdout, _stderr)
          raise NotImplementedError
        end

        # Apply the configuration using the CM system
        #
        # Configuration is available at #config_tmpdir
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @return [Boolean] true if the configuration was applied; false otherwise.
        #
        # @see config_tmpdir
        def run_masterless_mode(_stdout, _stderr)
          raise NotImplementedError
        end

      private

        def with_retries(attempts = 1, time_out = nil)
          attempts.times do |i|
            log.info "Running provisioner (try #{i + 1}/#{attempts})"
            return true if yield(i)
            sleep time_out if time_out && i < attempts - 1 # Sleep unless it's the last attempt
          end
          false
        end

        # Run a puppet command a return a boolean value (success, failure)
        #
        # @return [Boolean] true if command ran successfully; false otherwise.
        def run_cmd(*args)
          Cheetah.run(*args)
          true
        rescue Cheetah::ExecutionFailed
          false
        end
      end
    end
  end
end
