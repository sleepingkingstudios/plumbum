---
breadcrumbs:
  - name: Documentation
    path: '/'
---

# Dependencies

To make developing and testing Ruby projects easier, `Plumbum` defines a set of standard Dependencies. Each built-in dependency wraps an external interface, such as the file system or standard IO streams. Using standard dependencies allows you to wrap the side effects of your commands or other functions, making it easier (and safer) to test commands or redirect functionality.

Standard dependencies are defined using [providers](../providers) and used by [consumers](../consumers).

> Note: Dependencies were extracted from the <a href="https://www.sleepingkingstudios.com/plumbum" target="_blank">Cuprum::Cli</a> gem, also by Sleeping King Studios.

## Contents

- [Using Dependencies](#using-dependencies)
  - [Why Standard Dependencies?](#why-standard-dependencies)
- [Standard Dependencies](#standard-dependencies)
  - [Clock](#clock)
  - [File System](#file-system)
  - [Shell Command](#shell-command)
  - [Standard IO](#standard-io)
- [Mock Dependencies](#mock-dependencies)

## Using Dependencies

To use a standard dependency in a class, you need to do three things:

- First, include the `Plumbum::Consumer` module so you can use the `provider` and `dependency` DSL methods.
- Second, use the `provider` method to set the `Plumbum::Dependencies.provider` to provide dependencies to the class.
- Finally, use the `dependency` method to declare a dependency on one of the [standard dependencies](#standard-dependencies).

```ruby
class GreetCommand < Cuprum::Command
  include Plumbum::Consumer

  provider Plumbum::Dependencies.provider

  dependency :standard_io

  private

  def process(name = 'program')
    if name.nil? || name.empty?
      standard_io.write_error('Name is empty.')

      return
    end

    standard_io.write_output("Greetings, #{name}!")
  end
end

command = GreetCommand.new
command.call
#=> Outputs "Greetings, program!" to $stdout.

command.call(nil)
#=> Outputs "Name is empty." to $stderr.
```

In the above command, we use the [StandardIo](#standard-io) dependency to write to the `STDOUT` stream on success or the `STDERR` stream on failure.

[Back To Top](#)

### Why Standard Dependencies?

Why does the `GreetCommand` not use the core Ruby `puts` and `warn` methods? Why add a level of indirection to access the standard IO streams?

Using the standard dependencies allows you to wrap the side effects of your commands or other functions, such as reading to or writing from the file system, managing text input or output, or invoking shell commands. By using [providers](../providers) and [consumers](../consumers), standard dependencies give you more control over how those side effects are handled. For example, you could define a different provider for standard dependencies in the test environment, or inject [mock dependencies](#mock-dependencies) directly into your classes using [parameter dependencies](../consumers#parameter-dependencies).

The benefits for testing are straightforward: you can write unit tests on code that manages files or runs shell commands without needing a complicated test setup, without needing to juggle global or external state, and without worrying about potentially dangerous operations being run.

Beyond testing, using the standard dependencies as an abstraction layer allows you to **change** what each dependency means for a specific context, and even provide your own implementation. For example, you could define a custom [Standard IO](#standard-io) dependency wrapper that instead reads from and writes to specific files.

[Back To Top](#)

## Standard Dependencies

`Plumbum` defines the following standard dependencies:

- [Clock](#clock)
- [File System](#file-system)
- [Shell Command](#shell-command)
- [Standard IO](#standard-io)

[Back To Top](#)

### Clock

The [Clock](./clock) dependency wraps Ruby's native time functionality.

> @todo

[Back To Top](#)

### File System

The [FileSystem](./file-system) dependency wraps operations on the file system, such as reading from or writing to files.

> @todo

[Back To Top](#)

### Shell Command

The [ShellCommand](./shell-command) dependency wraps running shell commands and capturing output.

> @todo

[Back To Top](#)

### Standard IO

The [StandardIo](./standard-io) dependency wraps the standard input, output, and error IO streams.

> @todo

[Back To Top](#)

## Mock Dependencies

Each standard dependency defines a `Mock` version designed for use in your tests. The easiest way to use a mock dependency is by including [parameter dependencies](../consumers#parameter-dependencies) in your consumer.

```ruby
require 'plumbum/dependencies/clock/mock'

class Calendar
  include Plumbum::Consumer
  prepend Plumbum::Parameters

  provider Plumbum::Dependencies.provider

  dependency :clock

  def format_date
    clock.get_time.strftime('The current date is %A, %B %-d, %Y')
  end
end

current_time = Time.new(1982, 7, 9, in: 'Z')
mock         = Plumbum::Dependencies::Clock::Mock.new(current_time:)
calendar     = Calendar.new(clock: mock)
calendar.format_date
#=> 'The current date is Friday, July 9, 1982'
```

In addition to making test setup easier, using mock dependencies allows you to safely run tests with otherwise-dangerous side effects. For example, you can test a command that deletes a particular directory using a [FileSystem mock](./file-system#file-system-mocks).

> Note: Dependency mocks are *not* autoloaded. Make sure to include an explicit `require` statement if you want to use a mocked standard dependency.

[Back To Top](#)
