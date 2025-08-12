# frozen_string_literal: true

require 'rake'

desc 'Run rubocop'
task :rubocop do
  sh 'bundle exec rubocop'
end

desc 'Run specs'
task :spec do
  sh 'bundle exec rspec'
end

task default: %i[rubocop spec]
