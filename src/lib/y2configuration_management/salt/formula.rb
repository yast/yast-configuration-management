require "yaml"
require "pathname"
require "y2configuration_management/salt/form"

module Y2ConfigurationManagement
  module Salt
    # A formula on disk
    class Formula
      include Yast::Logger

      # Default path to formulas repository
      FORMULA_BASE_DIR = "/usr/share/susemanager/formulas".freeze
      FORMULA_DATA = "/srv/susemanager/formula_data".freeze

      # @return [String] Formula path
      attr_reader :path

      # @return [String] Formula metadata
      attr_reader :metadata

      # @return [Form] Formula form
      attr_reader :form

      def initialize(path)
        @path = path

        metadata_filename = File.join(@path, "metadata.yml")
        @metadata = YAML.load(File.read(metadata_filename))
        form_filename = File.join(@path, "form.yml")
        @form = Form.from_file(form_filename)
        @enabled = false
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

      # Return all the installed formulas
      def self.all(path = FORMULA_BASE_DIR)
        Dir.glob(path + "/metadata/*")
           .map { |p| Pathname.new(p) }
           .select(&:directory?)
           .map { |p| Formula.new(p) }
      end
    end
  end
end
