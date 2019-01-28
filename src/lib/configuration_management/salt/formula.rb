require "yaml"

module Y2ConfigurationManagement
  module Salt
    # A formula on disk
    class Formula
      include Yast::Logger

      # Default path to formulas repository
      FORMULA_BASE_DIR = "/space/git/formulas".freeze

      # @return [String] Formula path
      attr_reader :path

      # @return [String] Formula metadata
      attr_reader :metadata

      # @return [String] Formula form specification
      attr_reader :form

      # @return [String] Formula values
      attr_reader :values

      def initialize(path)
        @path = path

        metadata_filename = File.join(@path, "metadata.yml")
        @metadata = YAML.load(File.read(metadata_filename))
        form_filename = File.join(@path, "form.yml")
        @form = YAML.load(File.read(form_filename))
        @enabled = false
        @values = default_values
      end

      # whether to apply this formula
      def enabled?
        @enabled
      end

      attr_writer :enabled

      def name
        path.basename.to_s
      end

      def description
        metadata["description"]
      end

      # retrieves the sub form data for a given form group path
      def form_for_group(group)
        find_group(group, form)
      end

      def set_values_for_group(group, new_values)
        section = find_group(group, values)
        exclude = section.select { |_k, v| v.is_a?(Hash) }
        filtered_new_values = new_values.reject { |k, _v| exclude.include?(k) }
        section.merge!(filtered_new_values) if section.is_a?(Hash)
      end

      def values_for_group(group)
        group = find_group(group, values)
        group.reject { |_k, v| v.is_a?(Hash) }
      end

      def default_values
        _default_values(form)
      end

      # Return all the installed formulas
      def self.all(path = FORMULA_BASE_DIR)
        Dir.glob(path + "/*")
           .map { |p| Pathname.new(p) }
           .select(&:directory?)
           .map { |p| Formula.new(p) }
      end

    private

      def _default_values(hash)
        defaults = hash.each_with_object({}) do |element, all|
          key, values = element
          all[key] = values["$default"] if values.is_a?(Hash) && values.key?("$default")
        end

        groups = hash.select { |_k, v| v["$type"] == "group" }
        ret = groups.each_with_object(defaults) do |group, all|
          key, value = group
          subdefaults = _default_values(value)
          all[key] = subdefaults
        end
        ret
      end

      def find_group(group, hash)
        groups = group.split(".").drop(1)
        groups.inject(hash) do |m, g|
          return nil if m.nil?
          m[g.to_s]
        end
      end
    end
  end
end
