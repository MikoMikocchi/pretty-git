# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'yaml'
require_relative '../../../lib/pretty_git/render/yaml_renderer'

RSpec.describe PrettyGit::Render::YamlRenderer do
  let(:io) { StringIO.new }

  let(:data) do
    {
      report: 'authors',
      repo_path: '.',
      period: { since: nil, until: nil },
      items: [
        {
          author: 'Alice',
          author_email: 'a@example.com',
          commits: 2,
          additions: 5,
          deletions: 1,
          avg_commit_size: 3.0
        },
        {
          author: 'Bob',
          author_email: 'b@example.com',
          commits: 1,
          additions: 2,
          deletions: 0,
          avg_commit_size: 2.0
        }
      ],
      generated_at: '2025-01-31T00:00:00Z'
    }
  end

  it 'renders meta fields correctly' do
    described_class.new(io: io).call('authors', data, nil)
    parsed = YAML.safe_load(io.string)
    expect(parsed['report']).to eq('authors')
    expect(parsed['repo_path']).to eq('.')
  end

  it 'renders items array with expected values' do
    described_class.new(io: io).call('authors', data, nil)
    parsed = YAML.safe_load(io.string)
    expect(parsed['items']).to be_a(Array)
    expect(parsed['items'].size).to eq(2)
    expect(parsed['items'][0]['author']).to eq('Alice')
    expect(parsed['items'][1]['commits']).to eq(1)
  end
end
