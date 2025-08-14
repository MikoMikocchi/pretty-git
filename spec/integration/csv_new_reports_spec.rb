# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/render/csv_renderer'

RSpec.describe PrettyGit::Render::CsvRenderer do
  let(:io) { StringIO.new }
  let(:renderer) { described_class.new(io: io) }

  def header_for(report, items)
    io.truncate(0)
    io.rewind
    renderer.call(report, { report: report, items: items }, nil)
    io.string.lines.first&.chomp
  end

  it 'emits correct header for hotspots' do
    h = header_for('hotspots', [{ path: 'a.rb', score: 1, commits: 1, additions: 1, deletions: 0, changes: 1 }])
    expect(h).to eq('path,score,commits,additions,deletions,changes')
  end

  it 'emits correct header for churn' do
    h = header_for('churn', [{ path: 'a.rb', churn: 3, commits: 1, additions: 2, deletions: 1 }])
    expect(h).to eq('path,churn,commits,additions,deletions')
  end

  it 'emits correct header for ownership' do
    h = header_for('ownership', [{ path: 'a.rb', owner: 'A <a@ex>', owner_share: 60.0, authors: 2 }])
    expect(h).to eq('path,owner,owner_share,authors')
  end
end
