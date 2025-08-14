# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  # Ruby 3.4+: base64 is a stdlib gem, required by json_schemer
  gem 'base64', require: false
  # Ruby 3.4+: bigdecimal is a stdlib gem, required by json_schemer
  gem 'bigdecimal', require: false
  gem 'json_schemer', '~> 0.2'
  gem 'mdl', '~> 0.13', require: false
  gem 'nokogiri', '~> 1.16'
  gem 'rake', '~> 13.2'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.66', require: false
  gem 'rubocop-rspec', '~> 3.0', require: false
end
