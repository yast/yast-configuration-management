require "yast"
require "ui/dialog"
require "ui/event_dispatcher"

module Yast
  module CM
    module Dialogs
      # Running provisioner dialog
      #
      # This dialog displays information about the running provisioner.
      # Basically, it allows to examine the output.
      class Running < ::UI::Dialog
        include Yast::I18n
        include ::UI::EventDispatcher

        # @return [Integer] Seconds remaining for timeout
        attr_writer :remaining_time

        # Update progress
        #
        # @param [Array<String>] Text to be shown
        def add_lines(new_lines)
          value = Yast::UI.QueryWidget(Id(:progress), :Value)
          lines = new_lines.dup
          lines.unshift(value) unless value.empty?
          Yast::UI.ChangeWidget(
            Id(:progress),
            :Value,
            lines.join("<br>")
          )
        end

        # Determines seconds for timeout
        #
        # @return [Integer] Remaining seconds for timeout
        def remaining_time
          @remaining_time ||= 9
        end

        # Determines if the timer has been stopped or not
        # 
        # @return [Boolean] True if it was stopped; false otherwise.
        def timer_stopped?
          return @timer_stopped unless @timer_stopped.nil?
          @timer_stopped = false
        end

        # Stop timer
        def stop_timer!
          @timer_stopped = true
        end

        # Decrement timer
        #
        # @return [Integer] New value for timer
        def decrement_timer!
          @remaining_time -= 1
        end

        # Drive the dialog behavior
        #
        # * Runs a block showing the output.
        # * Handles [Ok] and [Stop] buttons.
        #
        # @yield Block to be called
        #
        # @see run_block
        def run(&block)
          create_dialog
          run_block(&block)
          enable_buttons
          event_loop
        ensure
          Yast::UI.CloseDialog
        end

        # Handler for the Ok button
        def ok_handler
          finish_dialog(:ok)
        end

        # Handler for the Stop button
        def stop_handler
          Yast::UI.ChangeWidget(Id(:stop), :Enabled, false)
          stop_timer!
        end

        # Handler for user's input timeout
        #
        # @see update_timer
        def timeout_handler
          if remaining_time.zero?
            finish_dialog(:timeout)
          else
            update_timer
          end
        end

        # Update timer
        def update_timer
          decrement_timer!
          Yast::UI.ChangeWidget(
            Id(:remaining_time),
            :Value,
            remaining_time.to_s
          )
        end

      protected

        # Run a block showing the output
        #
        # This method receives a block and shows all the information
        # sent to stdout and stderr channels.
        #
        # @yield Block to be called
        #
        # @see OutputHandler
        def run_block(&block)
          handler = OutputHandler.new(self)
          old_stdout, $stdout = $stdout, handler
          old_stderr, $stderr = $stderr, handler
          block.call
        ensure
          $stdout = old_stdout
          $stderr = old_stderr
        end

        # Dialog initial content
        #
        # @return [Yast::Term] Content
        def dialog_content
          HBox(
            VSpacing(20),
            VBox(
              Left(Heading(_("Running provisioner"))),
              VSpacing(0.5),
              VBox(
                HSpacing(70),
                RichText(Id(:progress), "")
              ),
              VSpacing(0.2),
              HCenter(Label(Id(:remaining_time), _("Please, wait"))),
              ButtonBox(
                PushButton(
                  Id(:ok),
                  Opt(:default, :okButton, :disabled),
                  Label.OKButton
                ),
                PushButton(
                  Id(:stop),
                  Opt(:cancelButton, :disabled),
                  Label.StopButton
                )
              )
            ),
            HSpacing(1)
          )
        end

        def enable_buttons
          Yast::UI.ChangeWidget(Id(:ok), :Enabled, true)
          Yast::UI.ChangeWidget(Id(:stop), :Enabled, true)
        end

        # Read user's input
        #
        # If timer is stopped, no timeout is set.
        #
        # @return [Symbol] User's input.
        def user_input
          timer_stopped? ? Yast::UI.UserInput : Yast::UI.TimeoutUserInput(1000)
        end

        # Auxiliar class used to update the dialog. This class looks like an IO
        # one to handler stdout/stderr.
        class OutputHandler
include Yast::Logger
          # @return [Array<String>] Lines written to stdout/stderr
          attr_accessor :lines
          # @return [Yast::CM::Dialogs::Running] Dialog to update
          attr_reader :dialog

          # Constructor
          #
          # @param dialog [Yast::CM::Dialogs::Running] Dialog to update
          def initialize(dialog)
            Yast.import "UI"
            @dialog = dialog
          end

          # Add a new line to the dialog
          #
          # @param line [String] Line to add
          def <<(line)
            dialog.add_lines(line.split("\n"))
          end

          # Fake implementations to look like an IO object.
          def write(_); end

          # Fake implementations to look like an IO object.
          def flush; end
        end
      end
    end
  end
end
