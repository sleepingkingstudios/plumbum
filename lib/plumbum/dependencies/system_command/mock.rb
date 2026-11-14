# frozen_string_literal: true

require 'plumbum/dependencies/system_command'

module Plumbum::Dependencies
  # Mock implementation of SystemCommand for testing purposes.
  class SystemCommand::Mock < Plumbum::Dependencies::SystemCommand
    # Data class providing a mock implementation of Process::Status.
    MockStatus = Data.define(:exitstatus) do
      # @return [true, false] true if the exit status is zero, otherwise false.
      def success? = exitstatus.zero?
    end

    # @param captures [Hash{String => Proc, Array[String, String, Integer]}]
    #   the captured values to return. If the captures Hash has a key matching
    #   the command, that value will be used to generate the result.
    def initialize(captures: {})
      super()

      @captures          = captures
      @recorded_commands = []
    end

    # @return [Array<String>] the commands recorded by the mock service.
    attr_reader :recorded_commands

    private

    attr_reader :captures

    def capture_command(command, **rest)
      recorded_commands << build_command(command, **rest)

      output, error, exitstatus =
        captures
        .fetch(command, ['', '', 0])
        .then { |capture| capture.is_a?(Proc) ? capture.call(**rest) : capture }

      CapturedOutput.new(
        output:,
        error:,
        status: MockStatus.new(exitstatus:)
      )
    end

    def spawn_command(command, **rest)
      recorded_commands << build_command(command, **rest)

      _, _, exitstatus =
        captures
        .fetch(command, ['', '', 0])
        .then { |capture| capture.is_a?(Proc) ? capture.call(**rest) : capture }

      MockStatus.new(exitstatus:)
    end
  end
end
