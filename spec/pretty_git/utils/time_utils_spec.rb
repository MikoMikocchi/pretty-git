# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pretty_git/utils/time_utils'

RSpec.describe PrettyGit::Utils::TimeUtils do
  describe '.to_utc_iso8601' do
    it 'returns nil for nil or blank' do
      expect(described_class.to_utc_iso8601(nil)).to be_nil
      expect(described_class.to_utc_iso8601('')).to be_nil
      expect(described_class.to_utc_iso8601('   ')).to be_nil
    end

    it 'passes through ISO8601 strings normalized to Z' do
      expect(described_class.to_utc_iso8601('2025-01-02T03:04:05Z')).to eq('2025-01-02T03:04:05Z')
      expect(described_class.to_utc_iso8601('2025-01-02T04:04:05+01:00')).to eq('2025-01-02T03:04:05Z')
    end

    it 'treats YYYY-MM-DD as midnight UTC' do
      expect(described_class.to_utc_iso8601('2025-01-02')).to eq('2025-01-02T00:00:00Z')
    end

    it 'accepts Time and normalizes to UTC' do
      t = Time.new(2025, 1, 2, 12, 34, 56, '+03:00')
      expect(described_class.to_utc_iso8601(t)).to eq('2025-01-02T09:34:56Z')
    end

    it 'raises ArgumentError for invalid values' do
      expect { described_class.to_utc_iso8601('not-a-time') }.to raise_error(ArgumentError, /Invalid datetime/)
    end
  end
end
