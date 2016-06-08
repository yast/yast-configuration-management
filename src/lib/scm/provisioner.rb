require "yast"
# FIXME: find another way to have pluggable-provisioners
require "scm/salt_provisioner"
require "forwardable"

module Yast
  module SCM
    class Provisioner
      extend Forwardable

      def_delegators :@provisioner, :packages, :run

      class << self
        # Current provisioner
        def current
          @current
        end

        # Set the provisioner to be used
        def current=(provisioner)
          @current = provisioner
        end
      end

      def initialize(type, args)
        @provisioner = find_provisioner(type).new(args)
      end

      def find_provisioner(type)
        Yast::SCM.const_get "#{type.capitalize}Provisioner"
      rescue NameError
        log.error "Provider for type '#{type}' not found"
        nil
      end
    end
  end
end
