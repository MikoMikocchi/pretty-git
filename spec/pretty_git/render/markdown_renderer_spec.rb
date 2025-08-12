# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../../lib/pretty_git/render/markdown_renderer'

RSpec.describe PrettyGit::Render::MarkdownRenderer do
  let(:io) { StringIO.new }

  it 'renders files report as a Markdown table' do
    data = {
      report: 'files',
      repo_path: '.',
      period: { since: nil, until: nil },
      items: [
        { path: 'a.txt', commits: 3, additions: 4, deletions: 4, changes: 8 },
        { path: 'b.txt', commits: 1, additions: 2, deletions: 0, changes: 2 }
      ],
      generated_at: '2025-01-31T00:00:00Z'
    }

    described_class.new(io: io).call('files', data, nil)

    lines = io.string.lines.map(&:chomp)
    expect(lines[0]).to eq('# Top Files')
    expect(lines[2]).to eq('| path | commits | additions | deletions | changes |')
    expect(lines[3]).to eq('|---|---|---|---|---|')
    expect(lines[4]).to eq('| a.txt | 3 | 4 | 4 | 8 |')
    expect(lines[5]).to eq('| b.txt | 1 | 2 | 0 | 2 |')
  end
end
