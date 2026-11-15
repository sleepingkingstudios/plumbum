---
---

# Plumbum

A minimal dependency injection framework for Ruby, using vanilla Ruby semantics to define and reference dependencies from different providers.

## Documentation

{% include pages/index-versions.md %}

## Getting Started

Add the gem to your `Gemfile` or `gemspec`:

```ruby
gem 'plumbum'
```

Require `Plumbum` in your code:

```ruby
require 'plumbum'
```

## Reference

Plumbum defines the following core components:

- **[Consumers](./consumers)**
  <br>
  Objects that use providers to access dependency values.
- **[Providers](./providers)**
  <br>
  Objects that declare dependencies and their definitions.

### Dependencies

Plumbum also defines a set of [standard dependencies](./dependencies) that wrap external interfaces, such as the file system or standard IO streams.

- **[Clock](./dependencies/clock)**
  <br>
  The Clock dependency wraps Ruby's native time functionality.
- **[FileSystem](./dependencies/file-system)**
  <br>
  The FileSystem dependency wraps operations on the file system, such as reading from or writing to files.
- **[ShellCommand](./dependencies/shell-command)**
  <br>
  The ShellCommand dependency wraps running shell commands and capturing output.
- **[StandardIo](./dependencies/standard-io)**
  <br>
  The StandardIo dependency wraps the standard input, output, and error IO streams.

For a full list of defined classes and objects, see [Reference](./reference).
