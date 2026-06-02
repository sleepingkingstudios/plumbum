---
breadcrumbs:
  - name: 'Documentation'
    path: '../..'
  - name: 'Versions'
    path: '..'
  - name: '0.1'
    path: '.'
---

# Consumers

A `Plumbum::Consumer` is an object that relies on one or more external dependencies. It defines an interface foro managing two types of values:

- [Dependencies](#managing-dependencies) are external values used by the consumer.
- [Providers](#managing-providers) make dependencies available to the consumer object.

For a full list of available methods, see the [Reference documentation](../reference/plumbum/consumer).

## Contents

- [Defining Consumers](#defining-consumers)
  - [Managing Providers](#managing-providers)
  - [Managing Dependencies](#managing-dependencies)
  - [Scoped Dependencies](#scoped-dependencies)
  - [Method Dependencies](#method-dependencies)
  - [Dependency Options](#dependency-options)
- [Parameter Dependencies](#parameter-dependencies)
- [Compatibility](#compatibility)

## Defining Consumers

To define a consumer, include the `Plumbum::Consumer` module in your class:

```ruby
module Library
  class BooksQuery
    include Plumbum::Consumer

    provider Library::REPOSITORY_PROVIDER

    dependency :repository

    def call(**params)
      repository.books.where(**params)
    end
  end
end
```

Our `BooksQuery` above has three parts:

- First, we call the `provider` class method to declare the `Library::REPOSITORY_PROVIDER` as a provider. This allows the query class to use dependencies defined by that provider.
- Next, we call the `dependency` class method to declare that the query relies on a `:repository` dependency. This automatically defines a `#repository` instance method for our query; when the `#repository` method is called, Plumbum iterates over the defined providers until it finds one that declares a `:repository` dependency. It then calls that provider and returns the provider's value for that dependency.
- Finally, we use our `#repository` class method to implement our business logic.

If multiple providers declare a requested dependency, then the last declared provider provides the value. This mirrors Ruby's semantics around declared methods, and allows for features like overriding a dependency value on a subclass by declaring a new provider that defines that dependency.

The values returned by dependency methods are memoized by default. To fetch a new value from the provider each time the method is called, pass the `:memoize` option to `.dependency` (see [Dependency Options](#dependency-options), below).

[Back To Top](#)

### Managing Providers

A consumer manages providers using the `.provider(provider)` class methods.

```ruby
provider Library::REPOSITORY_PROVIDER
```

Calling `.provider` registers the provider and makes its dependencies available to instances of the class. Providers are also inherited, so instances of a subclass can also reference providers declared on the parent class and the respective dependencies.

If you need to manually declare providers for a class, you can override the `#plumbum_providers` instance method, which returns an `Array` containing the available providers for that instance. Calling `super` and including the value in the returned array is strongly recommended.

[Back To Top](#)

### Managing Dependencies

Once the providers are declared, a consumer can then declare the dependencies it needs using the `.dependency(key, **options)` class method.

```ruby
dependency :repository
```

Calling `.dependency(:repository)` automatically defines a `#repository` instance method, which will return the value of the `:repository` dependency from a provider that defines it. If no provider defines the requested dependency, it will instead raise a `Plumbum::Errors::MissingDependencyError`.

The `.dependency` method can be called with [a number of options](#dependency-options). You can also call `.dependency` with multiple keys; each key given will be used to define a dependency method with the specified options.

[Back To Top](#)

### Scoped Dependencies

In some cases, your consumer object may depend on a scoped or nested property of a dependency, rather than the top-level value. Consider the case of a configuration object with the shape `{ network: { port: 3000 } }`. You can define a `:configuration` dependency, and then use methods on the returned object to access the nested value.

However, Plumbum provides an alternative in the form of scoped dependencies. To define a scoped dependency, pass a `String` or `Symbol` key with multiple identifier separated by periods (`.`).

```ruby
dependency 'configuration.network.port'
```

Instead of defining a `#configuration` method, this approach defines a `#port` method directly. Internally, the `#port` method searches the declared providers for one that defines a `:configuration` dependency, then navigates through that object's nested values to access the `:network` and then `:port` properties.

As an added bonus, scoped dependencies support both Hash-like values (using the `#[](key)` method) and regular objects (using method calls). This allows the same dependency call to access values from a `Hash` or from nested objects, such as a configuration `Struct` or `Data` object.

To define multiple dependencies with the same scope, you can pass the `:scope` keyword to `.dependency`:

```ruby
dependencies \
  :hostname,
  :port,
  scope: 'configuration.network'
```

[Back To Top](#)

### Method Dependencies

Extending the concept of scoped dependencies, you can define a dependency on a **method** of a dependency value as well as its properties. To define a method dependency, pass a scoped key where the last segment is preceded by a hash-mark (`#`).

```ruby
dependency 'services.#health_check'
```

This approach defines a `#health_check` method on the consumer. Internally, the `#health_check` method searches the declared providers for one that provides a `:services` dependency, then calls that object's `#health_check` method with any parameters passed when calling the consumer's `#health_check` method.

[Back To Top](#)

### Dependency Options

The `.dependency` method takes the following options:

**`:as`**

If the `:as` value is given, the generated method is defined with the specified name, rather than automatically named after the dependency or scoped property.

```ruby
# Defines an #app method.
dependency :application, as: :app
```

**`:default`**

If the `:default` value is given, the value will be returned when the consumer does not have a provider for the dependency. If the default value is a `Proc`, the default will be lazily evaluated *in the context of the consumer*. A default value *will not* be returned if a matching provider is defined but does not support the given scope.

```ruby
dependency :logger, default: -> { Logger.new }
```

**`:memoize`** (default: `true`)

If the `:memoize` flag is set, the consumer will only resolve the provider and dependency value the first time the method is called. All subsequent calls to the dependency method will return that same value. Make sure that the `:memoize` flag is set to `false` for values that change over time (such as a current time) or when the value otherwise changes between calls (such as a random number generator). Defaults to `true`.

```ruby
dependency :random_integer, memoize: false
```

**`:optional`** (default: `false`)

If the `:optional` flag is set, the consumer will return `nil` instead of raising an exception if there is no provider that declares the requested dependency. Defaults to `false`.

```ruby
dependency :console, optional: true
```

**`:predicate`** (default: `false`)

If the `:predicate` flag is set, a predicate method will also be generated on the consumer, using the method name with a trailing `?` character. The predicate method will return `true` if any provider defines the named dependency, and `false` if no provider defines the dependency. Defaults to `false`.

```ruby
# Also defines an #io_adapter? method.
dependency :io_adapter, predicate: true
```

**`:private`** (default: `false`)

If the `:private` flag is set, the generated methods (including a predicate method, if any) will be generated with a visibility of `private`. Defaults to `false`.

```ruby
dependency :secrets, private: true
```

**`:scope`**

If the `:scope` value is given, that scope will be combined with the dependency key or keys to determine the resolved path from the provided dependency to the returned value.

```ruby
# Defines a #port method that returns the value of configuration.network.port.
dependency :port, scope: 'configuration.network'
```

[Back To Top](#)

## Parameter Dependencies

One useful pattern when using testing consumers is to allow passing in dependency values directly to the constructor when initializing the consumer. Plumbum provides support for this pattern using `Plumbum::Parameters`:

```ruby
module Library
  class AuthorsQuery
    include Plumbum::Consumer
    include Plumbum::Parameters

    provider Library::REPOSITORY_PROVIDER

    dependency :authors, scope: :repository

    def call(**params)
      authors.where(**params)
    end
  end
end

repository = MockRepository.new
query      = AuthorsQuery.new(repository:)

query.repository
#=> returns the instance of MockRepository
```

[Back To Top](#)

## Compatibility

In the case where the application or some other library relies on the same `.dependency` and/or `.provider` DSL methods, Plumbum defines a compatibility mixin that prefixes the class methods as `.plumbum_dependency` and `.plumbum_provider`. To use the compatible consumer, use `Plumbum::Consumers::ScopedConsumer` instead of `Plumbum::Consumer` in your consumer class.

```ruby
module Library
  class SafeQuery
    include Plumbum::Consumers::ScopedConsumer

    plumbum_provider Library::REPOSITORY_PROVIDER

    plumbum_dependency :repository
  end
end
```

You can use the scoped `.plumbum_dependency` and `.plumbum_provider` methods in regular consumers as well, but including only `Plumbum::Consumers::ScopedConsumer` ensures there are no namespace collisions (unless the other library also prefixes methods with `plumbum_`).

[Back To Top](#)
