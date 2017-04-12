require "yast"
require "transfer/file_from_url"

module Yast
  module ConfigurationManagement
    # Wrapper around Transfer::FileFromUrl
    module FileFromUrlWrapper
      extend Yast::I18n
      extend Yast::Transfer::FileFromUrl

      # Helper method to simplify invocation to get_file_from_url
      #
      # @return [Boolean] true if the file was fetched; false otherwise.
      #
      # @see Yast::Transfer::FileFromUrl
      def self.get_file(source, target)
        hostname = source.port ? "#{source.host}:#{source.port}" : source.host.to_s
        get_file_from_url(
          scheme: source.scheme.to_s, host: hostname,
          urlpath: source.path.to_s, urltok: {}, destdir: "/",
          localfile: target.to_s
        )
      end
    end
  end
end
