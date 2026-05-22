# Plumbum

Plumbum is a minimal dependency injection framework for Ruby, using vanilla Ruby semantics to define and reference dependencies from different providers.

<blockquote>
  Read The
  <a href="https://www.sleepingkingstudios.com/plumbum" target="_blank">
    Documentation
  </a>
</blockquote>

Plumbum defines an interface for declaring, providing, and consuming object dependencies. It defines the following concepts:

- Dependencies - A value or object used in some part of your application, such as a data repository, a configuration hash, or an environment name.
- [Providers](http://sleepingkingstudios.github.io/plumbum/provider) - A `Provider` makes one or more dependencies available to other parts of the application.
- [Consumers](http://sleepingkingstudios.github.io/plumbum/consumer) - A `Consumer` declares what dependencies it relies on and what providers it consumes. Plumbum handles resolving those dependencies.

As an example, consider a data repository. From a query object's perspective, there should be one source of truth as to where the data is read and persisted - but where? In a global singleton? A repository object manually passed to the query? What if we want to use different data sources in the test environment?

Plumbum solves this problem by decoupling the *source* of the dependency from how the dependency is *used*. We start by defining a provider - in this case, let's call it a `RepositoryProvider`. We can initialize the provider with a different *value* in different environments - for example, using static fixtures in the test environment. Inside our query class, then, we declare a *dependency* on a `#repository` value. We also declare a *provider* relationship with our defined `RepositoryProvider`. And that's it - when we call `query.repository`, Plumbum resolves that dependency to the provider. Want to inject a different dependency value in a specific test? Include `Plumbum::Parameters` and you can provide dependencies by passing them in as constructor parameters.

## Why Plumbum?

Plumbum was designed to solve a specific problem: decoupling the *definition* from the *use* of dependent objects and functions. You should use Plumbum when:

- You have dependencies that are used across your application or far from where they are nominally defined. For example, a data repository object could be used across the application - in commands, in queries, in reports, and so on.
- The *values* of your dependencies can change based on scope or context. For example, an application might use different configuration values in the development, test, and production environments, or you want to use a global logger in most contexts but pass in a mock logger instance in unit tests.

In addition to managing dependencies like configuration and repositories, one critical use case I've found for Plumbum in my own projects is defining a facade service over functionality like reading/writing to the standard IO streams or performing file system operations. Doing so allows me to define and inject mock services that make unit testing both easier and more safe to run.

## About

Plumbum is tested against MRI Ruby 3.2 through 4.0.

### Documentation

Documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

### License

Plumbum is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is on [GitHub](https://github.com/sleepingkingstudios/plumbum). Community contributions are welcome - please feel free to fork or submit issues, bug reports or pull requests.

### Code of Conduct

Please note that the `Plumbum` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/plumbum/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

## Getting Started

Add the gem to your `Gemfile` or `gemspec`:

```ruby
gem 'plumbum'
```

Require `Plumbum` in your code:

```ruby
require 'plumbum'
```

### Identify Dependencies

Before writing any code to manage dependencies, stop and consider what your dependencies are. Our example is a library application with entities such as Author, Book, Patron, and Loan, and we want to manage our application's data persistence layer. Each entity is represented by a `collection` that wraps query and update methods for that entity, and we define a `repository` object that returns our collections.

```ruby
repository = SqlRepository.new(database_url:)
collection = repository.books

collection.where(author: 'Ursula K. LeGuin')
```

Lots of places in the code will need to reference the current repository - in particular, any functions that query the existing data or insert or update entities will need the repository, so passing in the value directly will quickly become unwieldy.

We could define a singleton, such as a `Repository.current` class method. But what if we need the *value* of the current repository to depend on context? Here are a few reasons we might want to do so:

- High-priority requests in production use reserved database connections.
- The repository in the test environment uses a different data store - Redis-backed instead of a SQL database.
- We define a test repository with specific fixtures for running feature tests against the UI.

### Define Providers

The solution Plumbum defines is a `Provider`, a special type of object that "provides" or returns a dependency when requested. The documentation for providers is <a href="https://www.sleepingkingstudios.com/plumbum/providers" target="_blank">available online</a>.

Each provider implements a simple interface:

- `provider.has?(name)` checks if the provider defines the named dependency.
- `provider.get(name)` returns the requested dependency.

`Plumbum` has pre-defined providers for wrapping single and plural dependencies. In our case, we want to define a provider for just one dependency, so we'll use the `Plumbum::OneProvider` class. Further, we want to make sure that once the `repository` is set, it can't be changed to a different value, so we use the `write_once:` flag.

```ruby
require 'plumbum'

module Library
  REPOSITORY_PROVIDER = Plumbum::OneProvider.new(:repository, write_once: true)
end
```

Notice that we are *not* initializing the repository with a value. Instead, we will do so lazily - in an initializer when running the server, or in the test setup when running unit tests.

```ruby
Library::REPOSITORY_PROVIDER.value = SqlRepository.new(database_url:)
```

This allows us to define a different value in each environment, and to defer setting the value until later in the startup process (for example, once we have loaded configuration values). However, since the `write_once:` flag is set, we ensure that the value can't be changed at a later point.

### Define Consumers

So, we've defined our `Provider`, allowing us to control how and when our `repository` value is defined and to access the value from anywhere in our application. That solves our immediate problem, but calling `repository = Library::REPOSITORY_PROVIDER.get(:repository)` everywhere isn't very elegant or efficient.

Thus, Plumbum defines the `Consumer` module which you can `include` in your class to manage providers and dependencies. The documentation for consumers is <a href="https://www.sleepingkingstudios.com/plumbum/consumers" target="_blank">available online</a>.

Let's define a query class that finds books with the requested author, using Plumbum to manage our dependencies.

```ruby
module Library
  module Queries
    class FindBooksByAuthor
      include Plumbum::Consumer

      provider Library::REPOSITORY_PROVIDER

      dependency :repository

      def call(author_name, **filters)
        author = repository.authors.find(name: author)
        books  = repository.books.where(**filters, author_id: author.id)

        {
          author:,
          books:
        }
      end
    end
  end
end
```

In our query class, we first include `Plumbum::Consumer` to define the DSL methods. We then declare a `provider` - in our case, the `Library::REPOSITORY_PROVIDER`, which makes a `repository` dependency available. Finally, we declare that the query has a `dependency :repository`. Doing so defines the `#repository` method, which searches the providers defined for the class until it finds one that defines a `:repository` dependency.

A more complex example might define multiple providers and dependencies. The `dependency` method in particular provides a number of advanced features:

- Dependency aliases: `dependency :application, as: :app`.
- Skip memoization: `dependency :request, memoize: false`.
- Scoped dependencies: `dependency 'config.network.default_server`.
- Method dependencies: `dependency '#restart', scope: :process_manager`.

Let's solve a specific problem for our query class - testing. We can already declare a different `repository` value in our test environment by assigning it to the provider in our test setup. But what if we want to pass in a `repository` value directly? That would allow us to write tests with a repository scoped to the individual test and with predefined seed data.

Plumbum provides a module to enable this specific functionality. Include `Plumbum::Parameters` in your class and you can pass in dependency values to the constructor.

```ruby
Library::Queries::FindBooksByAuthor.include(Plumbum::Parameters)

repository = MockRepository.new(authors: [], books: [])
query      = Library::Queries::FindBooksByAuthor.new(repository:)
```

For a full list of features, see the <a href="https://www.sleepingkingstudios.com/plumbum" target="_blank">Documentation</a>.
