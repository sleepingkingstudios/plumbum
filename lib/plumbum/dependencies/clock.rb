# frozen_string_literal: true

require 'plumbum/dependencies'

module Plumbum::Dependencies
  # Utility wrapping the current time and time calculations.
  #
  # @example Getting the Current Time
  #   Plumbum::Dependencies::Clock.new.get_time
  #
  # @example Measuring an Interval
  #   time_elapsed = Plumbum::Dependencies::Clock.new.measure do
  #     sleep 1
  #   end
  #
  #   time_elapsed #=> 1.0 # Approximately.
  class Clock
    # @return [Float] a monotonically increasing system clock time.
    def get_monotonic_time # rubocop:disable Naming/AccessorMethodName
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end

    # @return [Time] the current time in the UTC time zone.
    def get_time = Time.now(in: 'Z') # rubocop:disable Naming/AccessorMethodName
    alias current_time get_time
    alias now get_time

    # Measures the time elapsed while the block is run.
    #
    # @return [Float] the elapsed time in seconds.
    def measure
      start_time = get_monotonic_time

      yield

      get_monotonic_time - start_time
    end
  end
end
