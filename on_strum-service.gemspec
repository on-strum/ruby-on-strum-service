# frozen_string_literal: true

require_relative 'lib/on_strum/service/version'

Gem::Specification.new do |spec|
  spec.name        = 'on_strum-service'
  spec.version     = OnStrum::Service::VERSION
  spec.authors     = ['Serhiy Nazarov']
  spec.email       = %w[admin@on-strum.org]

  spec.summary     = %(on_strum-service)
  spec.description = %(Abstract class for service object scaffolding)

  spec.homepage    = 'https://github.com/on-strum/ruby-on-strum-service'
  spec.license     = 'MIT'

  spec.metadata    = {
    'homepage_uri'      => 'https://github.com/on-strum/ruby-on-strum-service',
    'changelog_uri'     => 'https://github.com/on-strum/ruby-on-strum-service/blob/master/CHANGELOG.md',
    'source_code_uri'   => 'https://github.com/on-strum/ruby-on-strum-service',
    'documentation_uri' => 'https://github.com/on-strum/ruby-on-strum-service/blob/master/README.md',
    'bug_tracker_uri'   => 'https://github.com/on-strum/ruby-on-strum-service/issues'
  }

  spec.required_ruby_version = '>= 2.5.0'
  spec.files = `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(bin|lib)/|.ruby-version|on_strum-service.gemspec|LICENSE}) }
  spec.require_paths = %w[lib]

  spec.add_development_dependency 'rake', '~> 13.2', '>= 13.2.1'
  spec.add_development_dependency 'rspec', '~> 3.12'
end
