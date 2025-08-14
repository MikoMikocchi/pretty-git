# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/render/markdown_renderer'

RSpec.describe PrettyGit::Render::MarkdownRenderer do
  let(:io) { StringIO.new }
  let(:renderer) { described_class.new(io: io) }

  def render_table(report, items)
    io.truncate(0)
    io.rewind
    renderer.call(report, { report: report, items: items }, nil)
    io.string.lines.map(&:chomp)
  end

  it 'emits correct table header for hotspots' do
    lines = render_table('hotspots', [{ path: 'a.rb', score: 1, commits: 1, additions: 1, deletions: 0, changes: 1 }])
    expect(lines[2]).to eq('| path | score | commits | additions | deletions | changes |')
  end

  it 'emits correct table header for churn' do
    lines = render_table('churn', [{ path: 'a.rb', churn: 3, commits: 1, additions: 2, deletions: 1 }])
    expect(lines[2]).to eq('| path | churn | commits | additions | deletions |')
  end

  it 'emits correct table header for ownership' do
    lines = render_table('ownership', [{ path: 'a.rb', owner: 'A <a@ex>', owner_share: 60.0, authors: 2 }])
    expect(lines[2]).to eq('| path | owner | owner_share | authors |')
  end

  it 'is deterministic for hotspots regardless of input item order' do
    a = [{ path: 'a.rb', score: 1, commits: 1, additions: 1, deletions: 0, changes: 1 },
         { path: 'b.rb', score: 2, commits: 2, additions: 1, deletions: 1, changes: 2 }]
    b = a.reverse
    lines_a = render_table('hotspots', a)
    lines_b = render_table('hotspots', b)
    expect(lines_a).to eq(lines_b)
  end
end
