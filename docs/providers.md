---
breadcrumbs:
  - name: Documentation
    path: './'
---

# Providers

A `Plumbum::Provider` is an object that is used to access one or more dependency values. It defines a single interface for accessing a dependency value regardless of the dependency scope - global, by environment, by request cycle or otherwise.

For a full list of available methods, see the [Reference documentation](../reference/plumbum/provider).

## Contents

- [Defining Providers](#defining-providers)
  - [Singular Providers](#singular-providers)
  - [Plural Providers](#plural-providers)
  - [Lazy Providers](#lazy-providers)
- [Provider Options](#provider-options)

## Defining Providers

Each provider must define the following methods:

- `#has?(key)`: Returns `true` if that provider defines a dependency with the requested key. The provider must accept both `String` and `Symbol` keys.
- `#get(key)`: Returns the dependency with the requested key, or `nil` if the provider does not define the dependency.

A provider can optionally define the `#set(key, value)` method to assign dependency values after the provider is initialized.

The easiest way to define a provider is to include `Plumbum::Provider` and override the private `#get_value`, `#has_value?`, and (optional) `#set_value` methods. `Plumbum::Provider` handles validating and normalizing key values, as well as tracking options for mutability and lazy initialization (see [Provider Options](#provider-options), below).

```ruby
module Library
  class ApplicationProvider
    def initialize(application:, configuration:, environment:, **options)
      super(**options)

      @values = { application:, configuration:, environment: }
    end

    private

    attr_reader :values

    def get_value(key)
      values[key.to_sym]
    end

    def has_value?(key)
      values.key?(key.to_sym)
    end
  end
end
```

[Back To Top](#)

### Singular Providers

One common pattern is a `Provider` that defines a single, static value. `Plumbum` defines the `OneProvider` for this purpose:

```ruby
module Library
  REPOSITORY_PROVIDER = Plumbum::OneProvider.new(:repository, write_once: true)
end

Library::REPOSITORY_PROVIDER.has?(:repository)
#=> false
Library::REPOSITORY_PROVIDER.get(:repository)
#=> nil

# Initialize the provider with a value (in the application initializers, in the
# test setup, etc)
Library::REPOSITORY_PROVIDER.value = SqlRepository.new(database_url:)
Library::REPOSITORY_PROVIDER.has?(:repository)
#=> true
Library::REPOSITORY_PROVIDER.get(:repository)
#=> an instance of SqlRepository
```

For a singular provider, we pass the key for the dependency provided by the provider (in the above example, `:repository`) and any options (in the example, `{ write_once: true }`). For available options, see [Provider Options](#provider-options), below.

We can also pass a `value:` keyword directly when initializing the provider:

```ruby
provider = Plumbum::OneProvider.new(:repository, value: SqlRepository.new(database_url:))
```

If a value is *not* given, the value can be set later if the provider allows a mutable value (using options `read_only: false` or `write_once: true`).

[Back To Top](#)

### Plural Providers

Similarly, we can use the `ManyProvider` to define multiple static values defined by a single `Provider`.

```ruby
module Library
  CONFIGURATION_PROVIDER = Plumbum::ManyProvider.new(
    values: {
      database_url: 'localhost:9292',
      hostname:     'localhost',
      port:         4000
    },
    read_only: true
  )
end

Library::CONFIGURATION_PROVIDER.has?(:database_url)
#=> true
Library::CONFIGURATION_PROVIDER.get(:database_url)
#=> 'localhost:9292'
```

For a plural provider, we pass the `values:` as a keyword, as well as any additional options for the provider. For available options, see [Provider Options](#provider-options), below.

A plural provider can also be initialized with an `Array` of dependency keys. These dependency values can be set later if the provider allows a mutable value (using options `read_only: false` or `write_once: true`).

[Back To Top](#)

### Lazy Providers

In some cases, the provider value can't be assigned when the provider is initialized. For example, the value may depend on code or configuration that has not yet been loaded. When you include the `Providers::Lazy` mixin, you can set a `Proc` as the provider value instead. When the dependency is first requested, the `Proc` will be called and the resulting value returned as the value of the dependency.

```ruby
module Library
  CURRENT_TIME_PROVIDER =
    Plumbum::OneProvider
    .new(:current_time, -> { Time.now })
    .extend(Plumbum::Providers::Lazy)
end
```

Using a lazy provider comes with a few caveats. First, any `Proc` passed in as a provider value will be evaluated and it's *returned value* returned as the dependency. If you need to return an actual `Proc` as a dependency from a lazy provider, you will need to wrap it in an outer `Proc` that will be evaluated.

Second, be careful around memoizing dependencies from a lazy provider. In the above case, we get a different value back each time we call `CURRENT_TIME_PROVIDER.get(:current_time)`, so we should set the `:memoize` option to `false` when defining our dependency (see [Consumer Options]({{site.baseurl}}/consumers#dependency-options)).

[Back To Top](#)

## Provider Options

When defining a provider, the following options are available:

**`:read_only`** (default: `true`)

If the `read_only` option is set, then attempts to set the provider value (or any value, for a plural provider) will fail and raise a `Plumbum::Errors::ImmutableError`.

**`:write_once`** (default: `false`)

If the `write_once` option is set, then the provider value can be set if and only if the current value is undefined (i.e. the provider was not initialized with a value for that dependency, even `nil`). This allows defining providers that can be set with a value at a later point, but raise an exception if that value would be later changed.

[Back To Top](#)
