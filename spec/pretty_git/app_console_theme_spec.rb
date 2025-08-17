# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/app'
require_relative '../../lib/pretty_git/filters'
require_relative '../../lib/pretty_git/render/console_renderer'

RSpec.describe PrettyGit::App do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def filters(no_color:, theme: 'basic')
    PrettyGit::Filters.new(
      repo_path: '.', branches: [], since: nil, until: nil,
      authors: [], exclude_authors: [], paths: [], exclude_paths: [],
      time_bucket: 'week', metric: nil, limit: 10, format: 'console',
      out: nil, no_color: no_color, theme: theme
    )
  end

  it 'passes theme through to ConsoleRenderer and enables color by default' do
    f = filters(no_color: false, theme: 'bright')
    renderer_double = instance_double(PrettyGit::Render::ConsoleRenderer, call: nil)
    allow(PrettyGit::Render::ConsoleRenderer).to receive(:new).and_return(renderer_double)

    described_class.new.run('summary', f, out: out, err: err)

    expect(PrettyGit::Render::ConsoleRenderer).to have_received(:new).with(io: out, color: true, theme: 'bright')
  end

  it "disables color when theme is 'mono' regardless of no_color flag" do
    f = filters(no_color: false, theme: 'mono')
    renderer_double = instance_double(PrettyGit::Render::ConsoleRenderer, call: nil)
    allow(PrettyGit::Render::ConsoleRenderer).to receive(:new).and_return(renderer_double)

    described_class.new.run('summary', f, out: out, err: err)

    expect(PrettyGit::Render::ConsoleRenderer).to have_received(:new).with(io: out, color: false, theme: 'mono')
  end

  it 'disables color when --no-color is set even if theme is bright' do
    f = filters(no_color: true, theme: 'bright')
    renderer_double = instance_double(PrettyGit::Render::ConsoleRenderer, call: nil)
    allow(PrettyGit::Render::ConsoleRenderer).to receive(:new).and_return(renderer_double)

    described_class.new.run('summary', f, out: out, err: err)

    expect(PrettyGit::Render::ConsoleRenderer).to have_received(:new).with(io: out, color: false, theme: 'bright')
  end
end
