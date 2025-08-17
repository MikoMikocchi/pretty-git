# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/render/json_renderer'

RSpec.describe 'Golden files stability (JSON)' do
  let(:io) { StringIO.new }
  let(:renderer) { PrettyGit::Render::JsonRenderer.new(io: io) }

  def render_and_read(report, result)
    io.truncate(0)
    io.rewind
    renderer.call(report, result, nil)
    io.string
  end

  def expect_matches_golden(name, actual)
    golden_path = File.expand_path("../fixtures/golden/#{name}.json", __dir__)
    if ENV['UPDATE_GOLDEN'] == '1'
      File.write(golden_path, actual)
    end
    expect(File).to exist(golden_path), "Golden file missing: #{golden_path}"
    expected = File.read(golden_path)
    expect(actual).to eq(expected), "Mismatch against golden: #{name}.json"
  end

  it 'hotspots.json stays stable' do
    # Items already sorted to match canonical order
    result = {
      report: 'hotspots',
      items: [
        { path: 'b.rb', score: 1, commits: 2, additions: 2, deletions: 1, changes: 3 },
        { path: 'a.rb', score: 1, commits: 1, additions: 1, deletions: 0, changes: 1 }
      ]
    }
    actual = render_and_read('hotspots', result)
    expect_matches_golden('hotspots', actual)
  end

  it 'churn.json stays stable' do
    result = {
      report: 'churn',
      items: [
        { path: 'b.rb', churn: 6, commits: 2, additions: 4, deletions: 2 },
        { path: 'a.rb', churn: 3, commits: 1, additions: 2, deletions: 1 }
      ]
    }
    actual = render_and_read('churn', result)
    expect_matches_golden('churn', actual)
  end

  it 'ownership.json stays stable' do
    result = {
      report: 'ownership',
      items: [
        { path: 'a.rb', owner: 'A <a@ex>', owner_share: 60.0, authors: 2 },
        { path: 'b.rb', owner: 'B <b@ex>', owner_share: 40.0, authors: 3 }
      ]
    }
    actual = render_and_read('ownership', result)
    expect_matches_golden('ownership', actual)
  end

  it 'files.json stays stable' do
    result = {
      report: 'files',
      items: [
        { path: 'b.rb', commits: 2, additions: 2, deletions: 1, changes: 3 },
        { path: 'a.rb', commits: 1, additions: 1, deletions: 0, changes: 1 }
      ]
    }
    actual = render_and_read('files', result)
    expect_matches_golden('files', actual)
  end

  it 'authors.json stays stable' do
    result = {
      report: 'authors',
      items: [
        { author: 'Alice', author_email: 'a@ex', commits: 3, additions: 50, deletions: 10, avg_commit_size: 20.0 },
        { author: 'Bob', author_email: 'b@ex', commits: 2, additions: 30, deletions: 5, avg_commit_size: 17.5 }
      ]
    }
    actual = render_and_read('authors', result)
    expect_matches_golden('authors', actual)
  end

  it 'languages.json stays stable' do
    result = {
      report: 'languages',
      metric: 'bytes',
      items: [
        { language: 'Ruby', bytes: 600, percent: 60.0, color: '#701516' },
        { language: 'JavaScript', bytes: 400, percent: 40.0, color: '#f1e05a' }
      ]
    }
    actual = render_and_read('languages', result)
    expect_matches_golden('languages', actual)
  end

  it 'activity.json stays stable' do
    result = {
      report: 'activity',
      items: [
        { bucket: 'day', timestamp: '2025-01-01T00:00:00Z', commits: 2, additions: 3, deletions: 1 },
        { bucket: 'day', timestamp: '2025-01-02T00:00:00Z', commits: 1, additions: 1, deletions: 0 }
      ]
    }
    actual = render_and_read('activity', result)
    expect_matches_golden('activity', actual)
  end

  it 'heatmap.json stays stable' do
    result = {
      report: 'heatmap',
      items: [
        { dow: 1, hour: 10, commits: 3 },
        { dow: 1, hour: 11, commits: 1 }
      ]
    }
    actual = render_and_read('heatmap', result)
    expect_matches_golden('heatmap', actual)
  end
end
