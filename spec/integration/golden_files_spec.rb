# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/render/yaml_renderer'

RSpec.describe 'Golden files stability (YAML)' do
  let(:io) { StringIO.new }
  let(:renderer) { PrettyGit::Render::YamlRenderer.new(io: io) }

  def render_and_read(report, result)
    io.truncate(0)
    io.rewind
    renderer.call(report, result, nil)
    io.string
  end

  def expect_matches_golden(name, actual)
    golden_path = File.expand_path("../fixtures/golden/#{name}.yaml", __dir__)
    expect(File).to exist(golden_path), "Golden file missing: #{golden_path}"
    expected = File.read(golden_path)
    expect(actual).to eq(expected), "Mismatch against golden: #{name}.yaml"
  end

  it 'hotspots.yaml stays stable' do
    result = {
      report: 'hotspots',
      items: [
        { path: 'a.rb', score: 1, commits: 1, additions: 1, deletions: 0, changes: 1 },
        { path: 'b.rb', score: 1, commits: 2, additions: 2, deletions: 1, changes: 3 }
      ]
    }
    actual = render_and_read('hotspots', result)
    expect_matches_golden('hotspots', actual)
  end

  it 'churn.yaml stays stable' do
    result = {
      report: 'churn',
      items: [
        { path: 'a.rb', churn: 3, commits: 1, additions: 2, deletions: 1 },
        { path: 'b.rb', churn: 6, commits: 2, additions: 4, deletions: 2 }
      ]
    }
    actual = render_and_read('churn', result)
    expect_matches_golden('churn', actual)
  end

  it 'ownership.yaml stays stable' do
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
end
