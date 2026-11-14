# frozen_string_literal: true

require 'plumbum/dependencies/clock'

module Plumbum::Dependencies
  # Mock implementation of Clock for testing purposes.
  class Clock::Mock < Plumbum::Dependencies::Clock
    # @param current_time [Time] the current time in UTC time zone.
    # @param monotonic_time [Numeric] the monotonic server time.
    def initialize(current_time: nil, monotonic_time: nil)
      super()

      @current_time   = current_time || Time.now(in: 'Z')
      @monotonic_time =
        monotonic_time || Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # @return [Numeric] the mocked monotonic time.
    def get_monotonic_time # rubocop:disable Naming/AccessorMethodName
      @monotonic_time
    end

    # @return [Time] the mocked current time.
    def get_time = @current_time # rubocop:disable Naming/AccessorMethodName
    alias current_time get_time
    alias now get_time
  end
end
