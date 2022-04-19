# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gem_name/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'gem_name'
  s.version     = GemName::VERSION
  s.summary     = 'Adds DPD as a Shipping Method to Spree Commerce'
  s.description = s.summary
  s.required_ruby_version = '>= 2.7.0'

  s.author       = 'MrBrdo'
  s.email        = 'mrbrdo@mrbrdo.net'
  s.homepage     = 'https://github.com/mrbrdo'
  s.license      = %q{MIT}

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 3.1.0', '< 5.0'
  s.add_dependency 'spree_auth_devise', '>= 3.1.0', '< 5.0'
  s.add_dependency 'spree_extension'
  s.add_dependency 'faraday'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'webdrivers', '~> 4.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot', '~> 4.7'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails', '~> 4.0.0.beta2'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'require_all'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'appraisal'
end
