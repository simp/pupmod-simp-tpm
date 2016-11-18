# ------------------------------------------------------------------------------
# NOTE: SIMP Puppet rake tasks support ruby 2.0 and ruby 2.1
# ------------------------------------------------------------------------------
gem_sources   = ENV.key?('SIMP_GEM_SERVERS') ? ENV['SIMP_GEM_SERVERS'].split(/[, ]+/) : ['https://rubygems.org']

gem_sources.each { |gem_source| source gem_source }

group :test do
  gem 'rake'
  gem 'puppet', ENV.fetch('PUPPET_VERSION',  '~>4')
  gem 'rspec'
  gem 'rspec-puppet'
  gem 'hiera-puppet-helper'
  gem 'puppetlabs_spec_helper'
  gem 'metadata-json-lint'
  gem 'puppet-lint-empty_string-check',   :require => false
  gem 'puppet-lint-trailing_comma-check', :require => false
  gem 'simp-rspec-puppet-facts', ENV.fetch('SIMP_RSPEC_PUPPET_FACTS_VERSION', '~> 1.3')
  gem 'simp-rake-helpers', ENV.fetch('SIMP_RAKE_HELPERS_VERSION', '~> 3.0')
end

group :development do
  gem 'travis'
  gem 'travis-lint'
  gem 'travish'
  gem 'puppet-blacksmith'
  gem 'puppet-strings'
  gem 'guard-rake'
  gem 'pry'
  gem 'pry-doc'

  # `listen` is a dependency of `guard`
  # from `listen` 3.1+, `ruby_dep` requires Ruby version >= 2.2.3, ~> 2.2
  gem 'listen', '~> 3.0.6'
end

group :system_tests do
  # This patch is required to fix Beaker's broken `aio` handling
  gem 'beaker' #, :git => 'https://github.com/trevor-vaughan/beaker.git', :branch => 'BKR-931'
  gem 'beaker-rspec'
  gem 'simp-beaker-helpers', ENV.fetch('SIMP_BEAKER_HELPERS_VERSION', '~> 1.5')
end
