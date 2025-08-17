# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'rexml/document'
require_relative '../../../lib/pretty_git/render/xml_renderer'

RSpec.describe PrettyGit::Render::XmlRenderer do
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

  it 'renders authors report meta and period correctly' do
    described_class.new(io: io).call('authors', data, nil)

    xml = REXML::Document.new(io.string)
    root = xml.root
    expect(root.name).to eq('authorsReport')
    expect(root.elements['report']).not_to be_nil
    expect(root.elements['report'].text).to eq('authors')
    expect(root.elements['repo_path'].text).to eq('.')
    expect(root.elements['generated_at'].text).to eq('2025-01-31T00:00:00Z')

    period = root.elements['period']
    expect(period).not_to be_nil
    expect(period.elements['since'].text.to_s).to eq('')
    expect(period.elements['until'].text.to_s).to eq('')
  end

  it 'renders authors items with details' do
    described_class.new(io: io).call('authors', data, nil)

    xml = REXML::Document.new(io.string)
    root = xml.root
    items = root.elements['items']
    expect(items).not_to be_nil
    item_elems = items.get_elements('item')
    expect(item_elems.length).to eq(2)
    expect(item_elems.first.elements['author'].text).to eq('Alice')
  end
end
