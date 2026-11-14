# frozen_string_literal: true

require 'stringio'

require 'plumbum/dependencies/standard_io'

module Plumbum::Dependencies
  # Mock implementation of StandardIo for testing purposes.
  class StandardIo::Mock < Plumbum::Dependencies::StandardIo
    # @overload append_for_read(*messages, io:)
    #   Utility method for appending readable data to a StringIO stream.
    #
    #   @param messages [Array<String>] the messages to append. Will be appended
    #     to the stream in the provided order.
    #   @param io [IO] the io stream to append.
    #
    #   @return [IO] the io stream.
    def self.append_for_read(*messages, io:)
      total_length = 0

      messages.each do |message|
        message += "\n" unless message.end_with?("\n")

        io.print(message)

        total_length += message.length
      end

      io.pos -= total_length

      io
    end

    # @param error_stream [IO] the error stream. Defaults to an instance of
    #   StringIO.
    # @param input_stream [IO] the input stream. Defaults to an instance of
    #   StringIO.
    # @param output_stream [IO] the output stream. Defaulst to an instance of
    #   StringIO.
    def initialize(
      error_stream:  StringIO.new,
      input_stream:  StringIO.new,
      output_stream: StringIO.new
    )
      super

      @combined_stream = StringIO.new
    end

    # @return [IO] a combined input/output stream representing all IO activity.
    attr_reader :combined_stream

    # @return [IO] the error stream
    def error_stream = super # rubocop:disable Lint/UselessMethodDefinition

    # @return [IO] the input stream.
    def input_stream = super # rubocop:disable Lint/UselessMethodDefinition

    # @return [IO] the output stream.
    def output_stream = super # rubocop:disable Lint/UselessMethodDefinition

    # (see Plumbum::Dependencies::StandardIo#read_input)
    def read_input
      message = super

      combined_stream.print(message) if message

      message
    end

    # (see Plumbum::Dependencies::StandardIo#write_output)
    def write_output(message = nil, newline: true)
      super

      newline ? combined_stream.puts(message) : combined_stream.print(message)
    end

    # (see Plumbum::Dependencies::StandardIo#write_error)
    def write_error(message = nil, newline: true)
      super

      newline ? combined_stream.puts(message) : combined_stream.print(message)
    end
  end
end
