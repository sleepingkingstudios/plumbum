# frozen_string_literal: true

require 'cuprum/cli/integrations/thor/registry'

Cuprum::Cli.initializer.call

load 'sleeping_king_studios/docs/tasks.rb'

registry = Cuprum::Cli::Integrations::Thor::Registry.new

# CI Commands
registry.register Cuprum::Cli::Commands::Ci.commands

# File Commands
registry.register Cuprum::Cli::Commands::File.commands
