require "yast"
require "ui/dialog"
require "ui/event_dispatcher"

Yast.import "Label"

module Y2ConfigurationManagement
  module Dialogs
    # Running provisioner dialog
    #
    # This dialog displays information about the running provisioner.
    # Basically, it allows to examine the output.
    class Running < ::UI::Dialog
      include Yast::I18n
      include ::UI::EventDispatcher

      # @return [Integer] Seconds remaining for timeout
      attr_reader :remaining_time

      # Constructor
      #
      # @param reporting_opts [Hash] Reporting reporting_opts
      # @option reporting_opts [Boolean,nil] :open_after_success Keep the dialog open after
      #   finishing successfuly
      # @option reporting_opts [Boolean,nil] :open_after_error Keep the dialog open after
      #   finishing with an error
      # @option reporting_opts [Integer,nil] :timeout_after_success Timeout after finishing
      #   successfuly. It only makes sense when `:open_after_success` is set to true.
      # @option reporting_opts [Integer,nil] :timeout_after_error Timeout after finishing with
      #   an error. It only makes sense when `:open_after_error` is set to true.
      def initialize(reporting_opts: {})
        super()
        @open_after_success = !!reporting_opts[:open_after_success]
        @open_after_error = !!reporting_opts[:open_after_error]
        @timeout_after_success = reporting_opts[:timeout_after_success].to_i
        @timeout_after_error = reporting_opts[:timeout_after_error].to_i
        @timer_running = false
      end

      # Update progress
      #
      # @param new_lines [Array<String>] Text to be shown
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

      # Determines if the timer has been stopped or not
      #
      # @return [Boolean] Whether the timer is running or not
      def timer_running?
        @timer_running
      end

      # Determines seconds for timeout
      #
      # @return [Integer] Remaining seconds for timeout
      def remaining_time
        @remaining_time ||= 9
      end

      # Stop timer
      def stop_timer
        @timer_running = false
      end

      # Start timer
      #
      # @param seconds [Integer] Seconds to start the count down from
      def start_timer(seconds)
        @remaining_time = seconds
        @timer_running = true
      end

      # Decrement timer
      #
      # @return [Integer] New value for timer
      def decrement_timer
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
        result = run_block(&block)
        return :ok unless open_after?(result)
        start_timer_if_needed(result)
        refresh_and_enable_buttons
        event_loop
      ensure
        Yast::UI.CloseDialog
      end

      # Determines whether the dialog should be kept open
      #
      # @param result [Boolean] Whether the block ran successfully or not
      # @return [Boolean] true if the dialog should be kept; false otherwise
      def open_after?(result)
        result ? @open_after_success : @open_after_error
      end

      # Starts the timer if needed
      #
      # The timer will be started if the corresponding `open_after_*` variable
      # is set to true and a timeout (`timeout_after_*`) was specified.
      #
      # @param result [Boolean] Whether the block ran successfully or not
      def start_timer_if_needed(result)
        if result
          @open_after_success && !@timeout_after_success.zero? &&
            start_timer(@timeout_after_success)
        else
          @open_after_error && !@timeout_after_error.zero? &&
            start_timer(@timeout_after_error)
        end
      end

      # Handler for the Ok button
      def ok_handler
        finish_dialog(:ok)
      end

      # Handler for the Stop button
      def stop_handler
        Yast::UI.ChangeWidget(Id(:stop), :Enabled, false)
        stop_timer
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
        decrement_timer
        Yast::UI.ReplaceWidget(Id(:status), Label(Id(:remaining_time), remaining_time.to_s))
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
        block.call(handler, handler)
      end

      # Dialog initial content
      #
      # @return [Yast::Term] Content
      def dialog_content
        textdomain "configuration_management"
        Yast.import "Label"
        HBox(
          VSpacing(20),
          VBox(
            Left(Heading(_("Running provisioner"))),
            VSpacing(0.5),
            VBox(
              HSpacing(70),
              RichText(Id(:progress), Opt(:autoScrollDown), "")
            ),
            VSpacing(0.2),
            ReplacePoint(Id(:status), Label(Id(:please_wait), Yast::Label.PleaseWaitMsg)),
            ReplacePoint(Id(:buttons), buttons_box)
          ),
          HSpacing(1)
        )
      end

      # Read user's input
      #
      # If timer is stopped, no timeout is set.
      #
      # @return [Symbol] User's input.
      def user_input
        timer_running? ? Yast::UI.TimeoutUserInput(1000) : Yast::UI.UserInput
      end

      # Refreshes status and buttons
      def refresh_and_enable_buttons
        Yast::UI.ReplaceWidget(Id(:buttons), buttons_box)
        Yast::UI.ChangeWidget(Id(:ok), :Enabled, true)
        if timer_running?
          Yast::UI.ChangeWidget(Id(:stop), :Enabled, true)
          update_timer
        else
          Yast::UI.ReplaceWidget(Id(:status), Empty())
        end
      end

      # Buttons box
      #
      # @return [Yast::Term] Buttons box
      def buttons_box
        buttons = []
        buttons << PushButton(
          Id(:ok),
          Opt(:default, :okButton, :disabled),
          Yast::Label.OKButton
        )

        if timer_running?
          buttons << PushButton(
            Id(:stop),
            Opt(:cancelButton, :disabled),
            Yast::Label.StopButton
          )
        end

        ButtonBox(*buttons)
      end

      # Auxiliar class used to update the dialog. This class looks like an IO
      # one to handler stdout/stderr.
      class OutputHandler
        # String encoding to use in order to avoid problems in the dialog
        ENCODING = "UTF-8".freeze

        # @return [Y2ConfigurationManagement::Dialogs::Running] Dialog to update
        attr_reader :dialog

        # Constructor
        #
        # @param dialog [Y2ConfigurationManagement::Dialogs::Running] Dialog to update
        def initialize(dialog)
          Yast.import "UI"
          @dialog = dialog
        end

        # Add a new line to the dialog
        #
        # @param line [String] Line to add
        def <<(line)
          dialog.add_lines(line.force_encoding(ENCODING).split("\n"))
        end

        # Fake implementations to look like an IO object.
        def write(_); end

        # Fake implementations to look like an IO object.
        def flush; end
      end
    end
  end
end
