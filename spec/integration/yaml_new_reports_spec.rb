# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'yaml'
require_relative '../../lib/pretty_git/render/yaml_renderer'

RSpec.describe PrettyGit::Render::YamlRenderer do
  let(:io) { StringIO.new }
  let(:renderer) { described_class.new(io: io) }

  def render(report, items)
    io.truncate(0)
    io.rewind
    renderer.call(report, { report: report, items: items }, nil)
    YAML.safe_load(io.string)
  end

  it 'is deterministic for hotspots regardless of input item order' do
    a = [{ 'path' => 'a.rb', 'score' => 1, 'commits' => 1, 'additions' => 1, 'deletions' => 0, 'changes' => 1 },
         { 'path' => 'b.rb', 'score' => 2, 'commits' => 2, 'additions' => 1, 'deletions' => 1, 'changes' => 2 }]
    b = a.reverse

    ya = render('hotspots', a.map { |h| h.transform_keys(&:to_sym) })
    yb = render('hotspots', b.map { |h| h.transform_keys(&:to_sym) })

    expect(ya['items'].map { |i| i['path'] }).to eq(%w[b.rb a.rb])
    expect(ya).to eq(yb)
  end

  it 'is deterministic for ownership regardless of input item order' do
    a = [{ 'path' => 'a.rb', 'owner' => 'A', 'owner_share' => 60.0, 'authors' => 2 },
         { 'path' => 'b.rb', 'owner' => 'B', 'owner_share' => 80.0, 'authors' => 1 }]
    b = a.reverse

    ya = render('ownership', a.map { |h| h.transform_keys(&:to_sym) })
    yb = render('ownership', b.map { |h| h.transform_keys(&:to_sym) })

    expect(ya['items'].map { |i| i['path'] }).to eq(%w[b.rb a.rb])
    expect(ya).to eq(yb)
  end
end
