---
---

# Plumbum

A minimal dependency injection framework for Ruby, using vanilla Ruby semantics to define and reference dependencies from different providers.

## Documentation

{% include snippets/index-versions.md %}

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

For a full list of defined classes and objects, see [Reference](./reference).
