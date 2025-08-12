# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/pretty_git/analytics/languages'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Languages do
  def write(path, bytes)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, 'x' * bytes)
  end

  def filters(repo_path, limit: 0, paths: nil, exclude_paths: nil)
    PrettyGit::Filters.new(
      repo_path: repo_path,
      time_bucket: 'week',
      limit: limit,
      format: 'json',
      no_color: true,
      paths: paths,
      exclude_paths: exclude_paths
    )
  end

  it 'calculates bytes per language and percentages, sorted by percent desc' do
    Dir.mktmpdir do |dir|
      write(File.join(dir, 'a.rb'), 10)   # Ruby
      write(File.join(dir, 'b.js'), 30)   # JavaScript

      res = described_class.call([].each, filters(dir))

      expect(res[:report]).to eq('languages')
      items = res[:items]
      expect(items.map { |i| i[:language] }).to eq(%w[JavaScript Ruby])

      js = items.find { |i| i[:language] == 'JavaScript' }
      rb = items.find { |i| i[:language] == 'Ruby' }
      expect(js[:bytes]).to eq(30)
      expect(rb[:bytes]).to eq(10)

      # 30/(30+10)=0.75 -> 75.0, 10/40=25.0
      expect(js[:percent]).to be_within(0.001).of(75.0)
      expect(rb[:percent]).to be_within(0.001).of(25.0)
    end
  end

  it 'respects include and exclude globs and ignores vendor/binary files' do
    Dir.mktmpdir do |dir|
      write(File.join(dir, 'keep.rb'), 50)
      write(File.join(dir, 'drop.js'), 100)
      write(File.join(dir, 'vendor/lib.rb'), 500)   # should be ignored
      write(File.join(dir, 'image.png'), 1000)      # binary ignored

      res = described_class.call([].each, filters(dir, paths: %w[**/*.rb], exclude_paths: %w[**/vendor/**]))

      items = res[:items]
      expect(items.size).to eq(1)
      expect(items.first[:language]).to eq('Ruby')
      expect(items.first[:bytes]).to eq(50)
      expect(items.first[:percent]).to be_within(0.001).of(100.0)
    end
  end

  it 'detects languages by filename (Makefile, Dockerfile) and applies limit' do
    Dir.mktmpdir do |dir|
      write(File.join(dir, 'Makefile'), 20)
      write(File.join(dir, 'Dockerfile'), 30)
      write(File.join(dir, 'x.py'), 40)

      res_all = described_class.call([].each, filters(dir))
      langs = res_all[:items].map { |i| i[:language] }
      expect(langs).to include('Makefile', 'Dockerfile', 'Python')

      res_lim = described_class.call([].each, filters(dir, limit: 2))
      expect(res_lim[:items].size).to eq(2)
      # top 2 by bytes should be Python (40) and Dockerfile (30)
      expect(res_lim[:items].map { |i| [i[:language], i[:bytes]] }).to eq([
        ['Python', 40], ['Dockerfile', 30]
      ])
    end
  end
end
