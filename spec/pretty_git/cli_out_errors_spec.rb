# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'fileutils'
require_relative '../../lib/pretty_git/cli'

RSpec.describe PrettyGit::CLI do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def run_cli(argv)
    described_class.run(argv.dup, out: out, err: err)
  end

  it 'returns 2 and prints error when --out points to a directory' do
    code = run_cli(['summary', '--out', '.'])
    expect(code).to eq(2)
    expect(err.string).not_to be_empty
  end

  it 'returns 2 and prints error when path is not writable' do
    # Create a temp dir and set it readonly, try to write inside without permission
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'subdir')
      Dir.mkdir(path)
      File.chmod(0o500, path) # read/execute only, no write
      target = File.join(path, 'out.json')
      code = run_cli(['authors', '--format', 'json', '--out', target])
      expect(code).to eq(2)
      expect(err.string).not_to be_empty
    ensure
      File.chmod(0o700, path) if File.exist?(path)
    end
  end
end
