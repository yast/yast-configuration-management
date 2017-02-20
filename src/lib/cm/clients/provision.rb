require "yast"
require "cm/runners/base"
require "cm/dialogs/running"
require "cm/config"

module Yast
  module CM
    module Clients
      class Provision < Client
        def run
          return false unless runner
          dialog = Yast::CM::Dialogs::Running.new
          dialog.run do |stdout, stderr|
            # Connect stdout and stderr with the dialog
            runner.run(stdout, stderr)
          end
          true
        end

      private

        def runner
          return @runner if @runner
          # FIXME: it should be able to recieve a config object
          @runner = Yast::CM::Runners::Base.runner_for(config) if config
        end

        def config
          @config ||= Config.load
        end
      end
    end
  end
end
