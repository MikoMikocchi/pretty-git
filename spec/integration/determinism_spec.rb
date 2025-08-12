# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/files'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Files do
  it 'produces same files order regardless of input order' do
    def fs(path, addn, delt)
      PrettyGit::Types::FileStat.new(path: path, additions: addn, deletions: delt)
    end

    def commit(files)
      PrettyGit::Types::Commit.new(
        sha: 'x', author_name: 'A', author_email: 'a@ex', authored_at: '2025-01-01T00:00:00Z',
        message: 'm', additions: files.sum(&:additions), deletions: files.sum(&:deletions), files: files
      )
    end

    commits_a = [
      commit([fs('b.rb', 3, 1), fs('a.rb', 2, 2)]),
      commit([fs('b.rb', 1, 1)])
    ]

    commits_b = [
      commit([fs('a.rb', 2, 2)]),
      commit([fs('b.rb', 1, 1)]),
      commit([fs('b.rb', 3, 1)])
    ]

    # Expected totals:
    # a.rb: commits=1, additions=2, deletions=2, changes=4
    # b.rb: commits=2, additions=4, deletions=2, changes=6
    # Sort by changes desc, then commits desc, then path asc -> b.rb first, then a.rb

    filters = PrettyGit::Filters.new(repo_path: '.', limit: 0)
    res_a = described_class.call(commits_a.each, filters)
    res_b = described_class.call(commits_b.each, filters)

    expect(res_a[:items]).to eq(res_b[:items])
    expect(res_a[:items].map { |i| i[:path] }).to eq(%w[b.rb a.rb])
  end
end
