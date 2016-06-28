require "yast"
require "uri"
require "transfer/file_from_url"

module Yast
  module SCM
    # This class retrieves keys from a given URL
    #
    # It tries to retrieve the keys from a given URL:
    #
    # * Public key
    # * Private key
    #
    # It tries to locate the files using:
    #
    # * some kind of ID (depends on the provisioner)
    # * MAC address (not implemented)
    # * hostname
    # * IP address (not implemented)
    # * default.pem and default.key (some default) 
    class KeyFinder
      include Yast::Transfer::FileFromUrl
      include Yast::I18n

      # @return [URI]
      attr_reader :keys_url
      # @return [String]
      attr_reader :id
      # @return [Array<String>]
      attr_reader :extensions

      EXTENSIONS = { key: "key", pub: "pub" }

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
        ret != nil
      end

      private

      def fetch_files(name, key, cert)
        key_url = keys_url.merge(File.join(keys_url.path, "#{name}.#{EXTENSIONS[:key]}"))
        pub_url = keys_url.merge(File.join(keys_url.path, "#{name}.#{EXTENSIONS[:pub]}"))

        get_file(key_url, key) && get_file(pub_url, cert)
      end

      # FIXME: DRY
      def get_file(source, target)
        get_file_from_url(
          scheme: source.scheme, host: source.host,
          urlpath: source.path.to_s, urltok: {}, destdir: "/",
          localfile: target.to_s)
      end

      # Temptative names
      def names
        [ id, hostname, "default" ].compact
      end

      # Hostname
      def hostname
        Yast.import "Hostname"
        Yast::Hostname.CurrentFQ()
      end
    end
  end
end
