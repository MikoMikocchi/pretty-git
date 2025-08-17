# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Filters do
  describe '#since_iso8601 / #until_iso8601' do
    it 'returns nil when value is nil or empty' do
      f = described_class.new
      expect(f.since_iso8601).to be_nil
      expect(f.until_iso8601).to be_nil
      f.since = ''
      f[:until] = '   '
      expect(f.since_iso8601).to be_nil
      expect(f.until_iso8601).to be_nil
    end

    it 'interprets YYYY-MM-DD as UTC midnight' do
      f = described_class.new(since: '2025-08-17')
      expect(f.since_iso8601).to eq('2025-08-17T00:00:00Z')
    end

    it 'normalizes Time with timezone to UTC' do
      t = Time.new(2025, 8, 17, 12, 30, 0, '+03:00')
      f = described_class.new(since: t)
      expect(f.since_iso8601).to eq('2025-08-17T09:30:00Z')
    end

    it 'parses ISO8601 string and normalizes to UTC' do
      f = described_class.new(since: '2025-08-17T12:30:00+03:00')
      expect(f.since_iso8601).to eq('2025-08-17T09:30:00Z')
    end

    it 'raises ArgumentError for invalid value' do
      f = described_class.new(since: 'not-a-date')
      expect { f.since_iso8601 }.to raise_error(ArgumentError, /Invalid datetime/)
    end
  end

  describe 'initialization compatibility' do
    it 'accepts a single Hash positional argument' do
      f = described_class.new({ limit: 5, format: 'json' })
      expect(f.limit).to eq(5)
      expect(f.format).to eq('json')
    end

    it 'remaps legacy :until to :until_at and emits deprecation to stderr' do
      expect do
        f = described_class.new(until: '2025-01-02')
        expect(f.until).to eq('2025-01-02')
        expect(f[:until]).to eq('2025-01-02')
        expect(f[:until_at]).to eq('2025-01-02')
        f.until = '2025-01-03'
        expect(f[:until_at]).to eq('2025-01-03')
      end.to output(/DEPRECATION: Filters initialized with :until/).to_stderr
    end
  end
end
