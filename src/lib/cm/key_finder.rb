require "yast"
require "uri"
require "cm/file_from_url_wrapper"

module Yast
  module CM
    # This class retrieves keys from a given URL
    #
    # It tries to retrieve the keys from a given URL:
    #
    # * Public key
    # * Private key
    #
    # It tries to locate the files using:
    #
    # * some kind of ID (depends on the configurator)
    # * MAC address (not implemented)
    # * hostname
    # * IP address (not implemented)
    # * default.pem and default.key (some default)
    class KeyFinder
      # @return [URI]
      attr_reader :keys_url
      # @return [String]
      attr_reader :id
      # @return [Array<String>]
      attr_reader :extensions

      EXTENSIONS = { key: "key", pub: "pub" }.freeze
      PUBLIC_KEY_PERMS  = 0o644
      PRIVATE_KEY_PERMS = 0o400

      def initialize(keys_url:, id: nil)
        @keys_url = keys_url
        @id = id
        @extensions = extensions
      end

      # Copies keys from a given URL
      #
      # @example Copy from usb device
      #   finder = KeyFinder.new(keys_url: URI("usb:/"))
      #   finder.fetch_to("/tmp/minion")
      #
      # @param target [Pathname] Destination (including the file basename).
      # @return [Boolean] true if keys were copied; false otherwise.
      def fetch_to(key, cert)
        ret = names.find { |n| fetch_files(n, key, cert) }
        !ret.nil?
      end

    private

      def fetch_files(name, key, cert)
        key_url = keys_url.merge(File.join(keys_url.path, "#{name}.#{EXTENSIONS[:key]}"))
        pub_url = keys_url.merge(File.join(keys_url.path, "#{name}.#{EXTENSIONS[:pub]}"))

        if FileFromUrlWrapper.get_file(key_url, key) &&
            FileFromUrlWrapper.get_file(pub_url, cert)
          set_permissions(key, cert)
          true
        else
          ::FileUtils.rm(key) if key.exist?
          false
        end
      end

      # Temptative names
      def names
        [id, hostname, "default"].compact
      end

      # Hostname
      def hostname
        Yast.import "Hostname"
        Yast::Hostname.CurrentFQ()
      end

      # Set keys permissions
      #
      # @see PRIVATE_KEY_PERMS
      # @see PUBLIC_KEY_PERMS
      def set_permissions(key, cert)
        ::FileUtils.chmod(PRIVATE_KEY_PERMS, key)
        ::FileUtils.chmod(PUBLIC_KEY_PERMS, cert)
      end
    end
  end
end
