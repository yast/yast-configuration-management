require "yast"
require "cheetah"
require "cm/cfa/minion"
require "cm/configurators/base"
require "pathname"

module Yast
  module CM
    module Configurators
      # Salt integration handler
      class Salt < Base
        PRIVATE_KEY_PATH = Pathname("/etc/salt/pki/minion/minion.pem").freeze
        PUBLIC_KEY_PATH = Pathname("/etc/salt/pki/minion/minion.pub").freeze

        # List of packages to install
        #
        # * `salt` includes the `salt-call` command.
        # * `salt-minion` is only needed in client mode
        #
        # @return [Hash] Packages to install/remove
        def packages
          salt_packages = ["salt"]
          salt_packages << "salt-minion" if mode == :client
          { "install" => salt_packages }
        end

      private

        # Update the minion's configuration file
        #
        # At this time, only the master server is handled.
        #
        # @see Yast::CM::Configurators::Base#update_configuration
        # @see #master
        def update_configuration
          return unless master.is_a?(::String)
          log.info "Updating minion configuration file"
          config = CFA::Minion.new
          config.load
          config.update(master: master, auth_tries: attempts, auth_timeout: timeout)
          config.save
        end

        # Return path to private key
        #
        # @return [Pathname] Path to private key
        def private_key_path
          PRIVATE_KEY_PATH
        end

        # Return path to public key
        #
        # @return [Pathname] Path to public_key
        def public_key_path
          PUBLIC_KEY_PATH
        end
      end
    end
  end
end
