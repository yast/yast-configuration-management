module Y2ConfigurationManagement
  module Salt
    # [Metadata][1] of [Salt Formulas][2].
    #
    # [1]: https://www.suse.com/documentation/suse-manager-3/3.2/susemanager-best-practices/html/book.suma.best.practices/best.practice.salt.formulas.and.forms.html#best.practice.salt.formulas.pillar
    # [2]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Metadata
      # @return [String] Formula description
      attr_reader :description

      # Constructor
      #
      # The original specification (deserialized metadata.yml).
      #
      # @param spec [Hash] The original specification (deserialized metadata.yml).
      def initialize(spec)
        @spec = spec
        @description = spec.fetch("description", "")
      end

      # Creates a new {Metadata} object reading the definition from a YAML file
      #
      # @param path [String] file path to read the form YAML definition
      # @return [Metadata]
      def self.from_file(path)
        definition = YAML.safe_load(File.read(path))
        new(definition)
      end
    end
  end
end
