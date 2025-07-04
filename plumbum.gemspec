# frozen_string_literal: true

require_relative 'lib/plumbum/version'

Gem::Specification.new do |gem|
  gem.name        = 'plumbum'
  gem.version     = Plumbum::VERSION
  gem.summary     = 'A dependency injection and management library for Ruby.'

  description = <<~DESCRIPTION
    A minimal dependency injection framework for Ruby, using vanilla Ruby
    semantics to define and reference dependencies from different providers.
  DESCRIPTION
  gem.description = description.strip.gsub(/\n +/, ' ')
  gem.authors     = ['Rob "Merlin" Smith']
  gem.email       = ['merlin@sleepingkingstudios.com']
  gem.homepage    = 'http://sleepingkingstudios.com'
  gem.license     = 'MIT'

  gem.metadata = {
    'bug_tracker_uri'       => 'https://github.com/sleepingkingstudios/plumbum/issues',
    'source_code_uri'       => 'https://github.com/sleepingkingstudios/plumbum',
    'rubygems_mfa_required' => 'true'
  }

  gem.required_ruby_version = '~> 3.2'
  gem.require_path = 'lib'
  gem.files        = Dir['lib/**/*.rb', 'LICENSE', '*.md']

  gem.add_runtime_dependency 'sleeping_king_studios-tools', '~> 1.2'
end
