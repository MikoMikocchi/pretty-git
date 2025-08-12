# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'json'
require_relative '../../../lib/pretty_git/render/json_renderer'

RSpec.describe PrettyGit::Render::JsonRenderer do
  let(:io) { StringIO.new }

  it 'outputs pretty JSON' do
    data = {
      report: 'authors',
      repo_path: '/repo',
      period: { since: '2025-01-01', until: '2025-01-31' },
      totals: { authors: 1, commits: 1, additions: 3, deletions: 0 },
      items: [
        { author: 'A', author_email: 'a@ex', commits: 1, additions: 3, deletions: 0, avg_commit_size: 3.0 }
      ],
      generated_at: '2025-01-31T00:00:00Z'
    }

    described_class.new(io: io).call('authors', data, nil)
    parsed = JSON.parse(io.string)

    expect(parsed['report']).to eq('authors')
    expect(parsed['items']).to be_a(Array)
    expect(parsed['items'].first['author']).to eq('A')
  end
end
