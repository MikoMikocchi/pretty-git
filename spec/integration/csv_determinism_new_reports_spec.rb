# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/render/csv_renderer'

RSpec.describe PrettyGit::Render::CsvRenderer do
  let(:io) { StringIO.new }
  let(:renderer) { described_class.new(io: io) }

  def render_csv(report, items)
    io.truncate(0)
    io.rewind
    renderer.call(report, { report: report, items: items }, nil)
    io.string
  end

  it 'is deterministic for hotspots regardless of input item order' do
    a = [
      { path: 'a.rb', score: 1, commits: 1, additions: 1, deletions: 0, changes: 1 },
      { path: 'b.rb', score: 2, commits: 2, additions: 1, deletions: 1, changes: 2 }
    ]
    b = a.reverse

    ca = render_csv('hotspots', a)
    cb = render_csv('hotspots', b)
    expect(ca).to eq(cb)
  end

  it 'is deterministic for churn regardless of input item order' do
    a = [
      { path: 'a.rb', churn: 1, commits: 1, additions: 1, deletions: 0 },
      { path: 'b.rb', churn: 3, commits: 2, additions: 2, deletions: 1 }
    ]
    b = a.reverse

    ca = render_csv('churn', a)
    cb = render_csv('churn', b)
    expect(ca).to eq(cb)
  end

  it 'is deterministic for ownership regardless of input item order' do
    a = [
      { path: 'a.rb', owner: 'A', owner_share: 60.0, authors: 2 },
      { path: 'b.rb', owner: 'B', owner_share: 80.0, authors: 1 }
    ]
    b = a.reverse

    ca = render_csv('ownership', a)
    cb = render_csv('ownership', b)
    expect(ca).to eq(cb)
  end
end
