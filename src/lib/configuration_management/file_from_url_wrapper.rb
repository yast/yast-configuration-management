require "yast"
require "transfer/file_from_url"

module Yast
  module ConfigurationManagement
    # Wrapper around Transfer::FileFromUrl
    module FileFromUrlWrapper
      extend Yast::I18n
      extend Yast::Transfer::FileFromUrl

      Yast.import "URL"

      # Helper method to simplify invocation to get_file_from_url
      #
      # @return [Boolean] true if the file was fetched; false otherwise.
      #
      # @see Yast::Transfer::FileFromUrl
      def self.get_file(source, target)
        url_tok = URL.Parse(source.to_s) # in order to take care about port
        get_file_from_url(
          scheme: source.scheme.to_s, host: source.host.to_s,
          urlpath: source.path.to_s, urltok: url_tok, destdir: "/",
          localfile: target.to_s
        )
      end
    end
  end
end
