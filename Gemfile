# Variables:
#
# SIMP_GEM_SERVERS | a space/comma delimited list of rubygem servers
# PUPPET_VERSION   | specifies the version of the puppet gem to load
puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : '~>3'
gem_sources   = ENV.key?('SIMP_GEM_SERVERS') ? ENV['SIMP_GEM_SERVERS'].split(/[, ]+/) : ['https://rubygems.org']

gem_sources.each { |gem_source| source gem_source }

group :test do
  gem "rake"
  gem 'puppet', puppetversion
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "simp-rspec-puppet-facts"

  # dependency hacks:
  gem "fog-google", '~> 0.0.9' # 0.1 dropped support for ruby 1.9

  # simp-rake-helpers does not suport puppet 2.7.X
  if "#{ENV['PUPPET_VERSION']}".scan(/\d+/).first != '2' &&
      # simp-rake-helpers and ruby 1.8.7 bomb Travis tests
      # TODO: fix upstream deps (parallel in simp-rake-helpers)
      RUBY_VERSION.sub(/\.\d+$/,'') != '1.8'
    gem 'simp-rake-helpers'
  end
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "vagrant-wrapper"
  gem "puppet-blacksmith"
  gem "guard-rake"
  gem 'pry'
  gem 'pry-doc'
end

group :system_tests do
  gem 'beaker'
  gem 'beaker-rspec'

  # 1.0.5 introduces FIPS-first acc tests
  gem 'simp-beaker-helpers', '>= 1.0.5'

  # dependency hacks:
  # NOTE: Workaround because net-ssh 2.10 is busting beaker
  # lib/ruby/1.9.1/socket.rb:251:in `tcp': wrong number of arguments (5 for 4) (ArgumentError)
  gem 'net-ssh', '~> 2.9.0'
end
