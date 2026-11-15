---
breadcrumbs:
  - name: Documentation
    path: '/'
  - name: Dependencies
    path: '/dependencies'
---

# Clock Dependency

The [Clock](./clock) dependency wraps Ruby's native time functionality.

```ruby
clock = Plumbum::Clock.new

clock.get_time
#=> an instance of Time with the current time in UTC.

clock.measure do
  sleep 1
end
#=> approximately 1.0
```

## Contents

- [Clock Methods](#clock-methods)
  - [#get_monotonic_time](#get_monotonic_time)
  - [#get_time](#get_time)
  - [#measure](#measure)
- [Clock Mocks](#clock-mocks)

## Clock Methods

The `Clock` dependency defines the following methods:

### `#get_monotonic_time`

The `#get_monotonic_time` method returns a monotonically-increasing timestamp as a `Float` of seconds since a system-determined reference point. The timestamp is not affected by changes to the system clock, leap seconds, or other time adjustments. This means that you can compare two calls to `#get_monotonic_time` to determine the elapsed time in seconds between the timestamps.

```ruby
start_time = clock.get_monotonic_time
#=> a Float

sleep 1

clock.get_monotonic_time - start_time
#=> approximately 1.0
```

You can also use the [#measure](#measure) method to calculate elapsed time.

Internally, this method uses `Process.clock_gettime(Process::CLOCK_MONOTONIC)`.

[Back to Top](#)

### `#get_time`

The `#get_time` method returns the current `Time` in the `UTC` time zone.

```ruby
timestamp = clock.get_time
timestamp.class
#=> Time
timestamp.zone
#=> "UTC"
```

[Back to Top](#)

### `#measure`

The `#measure` method calculates the time elapsed while the given block is evaluated. It returns the elapsed time as a `Float` of seconds.

```ruby
clock.measure do
  sleep 1
end
#=> approximately 1.0
```

If you need to calculate more than one interval, or cannot easily wrap the code to measure in a block, you can use the [#get_monotonic_time](#get_monotonic_time) method instead.

## Clock Mocks

You can use a `Clock::Mock` instance in place of a `Clock` dependency.

```ruby
require 'plumbum/dependencies/clock/mock'

current_time = Time.new(1982, 7, 9, in: 'Z')
mock         = Plumbum::Dependencies::Clock::Mock.new(current_time:)

mock.get_time
#=> 1982-07-09 00:00:00 UTC
```

A `Clock::Mock` can be initialized with an optional `current_time:` parameter, which sets the value of the time for that clock. If a current time is not given, it will default to the value of `Time.now(in: 'Z')` when the mock is initialized.

[Back to Top](#)
