require "yast"

module Yast
  module SCM
    class Provisioner
      include Yast::Logger

      # @return [String] Master server hostname
      attr_reader :master
      # @return [Integer] Number of authentication retries
      attr_reader :auth_retries
      # @return [Integer] Authentication timeout for each retry
      attr_reader :auth_timeout

      class << self
        # Current provisioner
        def current
          @current
        end

        # Set the provisioner to be used
        def current=(provisioner)
          @current = provisioner
        end

        def provisioner_for(type, config)
          provisioner_class(type).new(config)
        end

        def provisioner_class(type)
          require "scm/#{type}_provisioner"
          Yast::SCM.const_get "#{type.capitalize}Provisioner"
        rescue NameError, LoadError
          raise "Provisioner for '#{type}' not found"
        end
      end

      # Constructor
      #
      # @param config [Hash] options
      # @option config [Integer] auth_retries Number of authentication retries
      # @option config [Integer] auth_timeout Authentication timeout for each retry
      def initialize(config = {})
        log.info "Initializing provisioner #{self.class.name} with #{config}"
        @master       = config[:master]
        @auth_retries = config[:auth_retries] || 3
        @auth_timeout = config[:auth_timeout] || 10
      end

      # Apply the configuration
      #
      # @see update_config_file
      # @see apply
      def run
        update_configuration
        apply
      end

    private

      def update_configuration
        raise NotImplementedError
      end

      def apply
        auth_retries.times do |i|
          log.info "Applying configuration (try #{i + 1}/#{auth_retries})"
          return true if try_to_apply
        end
        false
      end

      def try_to_apply
        raise NotImplementedError
      end
    end
  end
end
