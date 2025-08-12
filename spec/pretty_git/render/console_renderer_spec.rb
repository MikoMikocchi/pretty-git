# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../../lib/pretty_git/render/console_renderer'

RSpec.describe PrettyGit::Render::ConsoleRenderer do
  let(:io) { StringIO.new }

  def summary_data
    {
      report: 'summary',
      repo_path: '/repo',
      period: { since: '2025-01-01', until: '2025-01-31' },
      totals: { commits: 3, authors: 2, additions: 9, deletions: 3 },
      top_authors: [
        { author: 'A', commits: 2, additions: 4, deletions: 3, avg_commit_size: 3.5 },
        { author: 'B', commits: 1, additions: 5, deletions: 0, avg_commit_size: 5.0 }
      ],
      top_files: [
        { path: 'x.rb', commits: 2, additions: 4, deletions: 3, changes: 7 }
      ],
      generated_at: '2025-01-31T00:00:00Z'
    }
  end

  def authors_data
    {
      report: 'authors',
      repo_path: '/repo',
      period: { since: '2025-01-01', until: '2025-01-31' },
      totals: { authors: 2, commits: 3, additions: 9, deletions: 3 },
      items: [
        { author: 'A', author_email: 'a@ex', commits: 2, additions: 4, deletions: 3, avg_commit_size: 3.5 },
        { author: 'B', author_email: 'b@ex', commits: 1, additions: 5, deletions: 0, avg_commit_size: 5.0 }
      ],
      generated_at: '2025-01-31T00:00:00Z'
    }
  end

  it 'renders summary with headers and totals' do
    described_class.new(io: io, color: false).call('summary', summary_data, nil)
    out = io.string
    expect(out).to include('Summary for /repo')
    expect(out).to include('Period: 2025-01-01 .. 2025-01-31')
    expect(out).to include('Totals: commits=3 authors=2 +9 -3')
    expect(out).to include('Top Authors')
    expect(out).to include('author commits additions deletions avg_commit_size')
    expect(out).to include('Top Files')
    expect(out).to include('path commits additions deletions changes')
    expect(out).to include('Generated at: 2025-01-31T00:00:00Z')
  end

  it 'renders authors with headers and items' do
    described_class.new(io: io, color: false).call('authors', authors_data, nil)
    out = io.string
    expect(out).to include('Authors for /repo')
    expect(out).to include('Totals: authors=2 commits=3 +9 -3')
    expect(out).to include('author author_email commits additions deletions avg_commit_size')
    expect(out).to include('Generated at: 2025-01-31T00:00:00Z')
  end
end
