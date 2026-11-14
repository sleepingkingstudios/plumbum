# frozen_string_literal: true

require 'plumbum/dependencies'

module Plumbum::Dependencies
  # Utility wrapping standard input, output, and error IO streams.
  class StandardIo
    ANSI_COLORS = {
      'black'  => 0,
      'blue'   => 34,
      'green'  => 32,
      'purple' => 35,
      'red'    => 31,
      'yellow' => 33
    }.freeze
    private_constant :ANSI_COLORS

    # @param error_stream [IO] the error stream. Defaults to $stderr.
    # @param input_stream [IO] the input stream. Defaults to $stdin.
    # @param output_stream [IO] the output stream. Defaulst to $stdout.
    def initialize(
      error_stream:  -> { $stderr },
      input_stream:  -> { $stdin },
      output_stream: -> { $stdout }
    )
      @lazy_error_stream  = error_stream
      @lazy_input_stream  = input_stream
      @lazy_output_stream = output_stream
    end

    # Wraps the text in an ANSI color escape code.
    #
    # @param text [String] the text to colorize.
    # @param color [String] the color to apply.
    #
    # @return [String] the colorized string.
    #
    # @raise [KeyError] if the requested color does not have an escape code.
    def color(text, color)
      color_code = ANSI_COLORS.fetch(color.to_s)

      "\e[#{color_code}m#{text}\e[0m"
    end

    # Requests a newline-terminated string from the input stream.
    #
    # @return [String] the returned input string.
    def read_input
      input_stream.gets
    end

    # Writes the given message to the error stream.
    #
    # If no error message is given, prints a newline only.
    #
    # @param message [String, nil] the message to write.
    # @param newline [true, false] if true, appends a newline to the message if
    #   it does not have a newline. Defaults to true.
    #
    # @return [nil]
    def write_error(message = nil, newline: true)
      newline ? error_stream.puts(message) : error_stream.print(message)
    end

    # Writes the given message to the output stream.
    #
    # If no message is given, prints a newline only.
    #
    # @param message [String, nil] the message to write.
    # @param newline [true, false] if true, appends a newline to the message if
    #   it does not have a newline. Defaults to true.
    #
    # @return [nil]
    def write_output(message = nil, newline: true)
      newline ? output_stream.puts(message) : output_stream.print(message)
    end

    private

    def error_stream
      @error_stream ||=
        if @lazy_error_stream.is_a?(Proc)
          @lazy_error_stream.call
        else
          @lazy_error_stream
        end
    end

    def input_stream
      @input_stream ||=
        if @lazy_input_stream.is_a?(Proc)
          @lazy_input_stream.call
        else
          @lazy_input_stream
        end
    end

    def output_stream
      @output_stream ||=
        if @lazy_output_stream.is_a?(Proc)
          @lazy_output_stream.call
        else
          @lazy_output_stream
        end
    end
  end
end
