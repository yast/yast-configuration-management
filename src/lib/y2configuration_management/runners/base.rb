require "yast"
require "pathname"
require "cheetah"

Yast.import "Installation"

module Y2ConfigurationManagement
  # This classes in this module are responsible for running the provisioning tools (Salt or Puppet).
  #
  # As usual, the {Base} class defines the common bits, while {Salt} and {Puppet} implement the
  # suport for Salt and Puppet provisioners.
  module Runners
    class UnknownRunner < StandardError; end

    # A runner is a class which takes care of using a provisioner (Salt, Puppet, etc.)
    # to configure the system.
    class Base
      include Yast::Logger

      # @return [Configurations::Salt] Configuration object
      attr_reader :config

      class << self
        # Return the runner for a given CM system and a configuration
        def for(config)
          class_for(config.type).new(config)
        end

        # Return the configurator class to handle a given CM system
        #
        # It tries to find the definition.
        #
        # @param type [String] CM type ("salt", "puppet", etc.)
        # @return [Class] Runner class
        def class_for(type)
          require "y2configuration_management/runners/#{type}"
          Y2ConfigurationManagement::Runners.const_get type.capitalize
        rescue NameError, LoadError
          raise UnknownRunner, "Runner for '#{type}' not found"
        end
      end

      # Constructor
      #
      # @param config [Hash] config
      # @option config [Integer] :mode          Operation's mode
      # @option config [Integer] :auth_attempts Number of authentication attempts
      # @option config [Integer] :auth_time_out Authentication time out for each attempt
      def initialize(config)
        log.info "Initializing runner #{self.class.name}"
        @config = config
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
        without_zypp_lock do
          send("run_#{config.mode}_mode", stdout, stderr)
        end
      end

    protected

      # Apply the configuration using the CM system
      #
      # To be redefined by inheriting classes.
      #
      # @param _stdout [IO] Standard output channel used by the configurator
      # @param _stderr [IO] Standard error channel used by the configurator
      #
      # @return [Boolean] true if the configuration was applied; false otherwise.
      def run_client_mode(_stdout, _stderr)
        raise NotImplementedError
      end

      # Apply the configuration using the CM system
      #
      # Configuration is available at #config_tmpdir
      #
      # @param _stdout [IO] Standard output channel used by the configurator
      # @param _stderr [IO] Standard error channel used by the configurator
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

      # Run a provisioner command a return a boolean value (success, failure)
      #
      # @return [Boolean] true if command ran successfully; false otherwise.
      def run_cmd(*args)
        args.last[:chroot] = Yast::Installation.destdir
        Cheetah.run(*args)
        true
      rescue Cheetah::ExecutionFailed
        false
      end

      # We're not supposed to call without_zypp_lock recursively.
      # In that case, we raise an exception to be safe.
      class WithoutZyppLockNotAllowed < StandardError; end

      # Run a block without the zypp lock
      #
      # You could consider this a hack and it should be used carefully.
      #
      # In this case, this behaviour is needed in order to be able to install
      # packages using a provisioner (Salt, Puppet, etc.). The reason is that
      # libzypp is locked and it won't be released until YaST finishes (too late).
      #
      # @param block [Proc] Block to run
      # @see WithouthZyppLockNotAllowed
      def without_zypp_lock(&block)
        raise WithoutZyppLockNotAllowed if File.exist?(zypp_pid_backup)
        begin
          if File.exist?(zypp_pid)
            log.info "Backing up #{zypp_pid} into #{zypp_pid_backup}"
            ::FileUtils.mv(zypp_pid, zypp_pid_backup) if File.exist?(zypp_pid)
          end
          block.call
        ensure
          if File.exist?(zypp_pid_backup)
            log.info "Restoring #{zypp_pid} from #{zypp_pid_backup}"
            ::FileUtils.mv(zypp_pid_backup, zypp_pid)
          end
        end
      end

      # Return the libzypp lock file
      #
      # @return [Pathname] Absolute path to zypp.pid
      def zypp_pid
        @zypp_pid ||= Pathname.new(Yast::Installation.destdir).join("var", "run", "zypp.pid")
      end

      # Return the libzypp backup lock file
      #
      # @return [Pathname] Absolute path to zypp.pid backup file
      def zypp_pid_backup
        @zypp_pid_backup ||= zypp_pid.sub_ext(".save")
      end
    end
  end
end
