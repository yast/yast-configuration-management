require "yast"
require "cwm"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/form_controller"
require "y2configuration_management/widgets/form"
require "byebug"

# Yast.import "CWM"
# Yast.import "Wizard"

module Yast
  class ExampleDialog
    include Yast::I18n
    include Yast::UIShortcuts
    def run
      textdomain "configuration_management"

      form_spec = Y2ConfigurationManagement::Salt::Form.from_file("test/fixtures/form.yml")
      controller = Y2ConfigurationManagement::Salt::FormController.new(form_spec)
      controller.render
    end
  end
end

Yast::ExampleDialog.new.run
