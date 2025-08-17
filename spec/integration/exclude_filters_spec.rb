# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe 'Exclude filters integration' do
  def run(cmd, chdir: nil)
    out = `#{cmd}`
    raise "Command failed: #{cmd}" unless $CHILD_STATUS.success?

    out
  end

  it 'excludes commits by author and excludes paths via pathspec' do
    Dir.mktmpdir('pg_git_') do |dir|
      Dir.chdir(dir) do
        run 'git init -q'
        run 'git config user.name "Alice"'
        run 'git config user.email "alice@example.com"'

        # Commit by Alice in lib/
        File.write('lib.rb', "puts 'hi'\n")
        run 'git add lib.rb'
        run 'git commit -q -m "feat: alice" --author "Alice <alice@example.com>" --date "2025-01-02T00:00:00Z"'

        # Commit by Bot in vendor/
        Dir.mkdir('vendor')
        File.write('vendor/data.txt', "x\n")
        run 'git add vendor/data.txt'
        run 'git commit -q -m "chore: bot" --author "CI Bot <bot@example.com>" --date "2025-01-03T00:00:00Z"'

        filters = PrettyGit::Filters.new(
          repo_path: dir,
          branches: [],
          authors: [],
          exclude_authors: ['bot'],
          paths: [],
          exclude_paths: ['vendor/**'],
          since: nil,
          until: nil,
          time_bucket: nil,
          limit: 0,
          format: 'json'
        )

        enum = PrettyGit::Git::Provider.new(filters).each_commit
        commits = enum.to_a

        # Only Alice commit should pass (bot author excluded; vendor path excluded)
        expect(commits.size).to eq(1)
        c = commits.first
        expect(c.author_name).to include('Alice')
        expect(c.files.map(&:path)).to include('lib.rb')
        expect(c.files.map(&:path)).not_to include('vendor/data.txt')
      end
    end
  end
end
