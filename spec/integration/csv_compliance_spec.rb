# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/render/csv_renderer'

RSpec.describe PrettyGit::Render::CsvRenderer do
  let(:io) { StringIO.new }
  let(:renderer) { described_class.new(io: io) }

  let(:data) do
    {
      report: 'authors',
      repo_path: '.',
      period: { since: nil, until: nil },
      items: [
        {
          author: 'Doe, John',
          author_email: 'john@example.com',
          commits: 1,
          additions: 10,
          deletions: 2,
          avg_commit_size: 12.0
        },
        {
          author: 'Alice "A."',
          author_email: 'a@example.com',
          commits: 2,
          additions: 5,
          deletions: 1,
          avg_commit_size: 3.0
        }
      ],
      generated_at: '2025-01-31T00:00:00Z'
    }
  end

  it 'emits UTF-8 with header' do
    renderer.call('authors', data, nil)
    csv = io.string
    expect(csv.encoding.name).to eq('UTF-8')
    header = csv.lines.first.chomp
    expect(header).to eq('author,author_email,commits,additions,deletions,avg_commit_size')
  end

  it 'properly quotes commas and quotes per RFC 4180' do
    renderer.call('authors', data, nil)
    rows = io.string.lines.map(&:chomp)
    # Row for "Doe, John" should quote the field with comma
    expect(rows[1]).to start_with('"Doe, John",john@example.com,1,10,2,12.0')
    # Row for author with quotes should double quotes inside
    # Alice "A." -> "Alice ""A."""
    expect(rows[2]).to start_with('"Alice ""A.""",a@example.com,2,5,1,3.0')
  end
end
