# frozen_string_literal: true

module GoldenHelper
  # format: :yaml | :json | :xml | :csv
  def expect_matches_golden(format, name, actual)
    path = golden_path_for(format, name)
    File.write(path, actual) if update_golden?
    expect(File).to exist(path), "Golden file missing: #{path}"
    expected = File.read(path)
    message = "Mismatch against golden: #{name}.#{golden_ext(format)}"
    expect(normalize_for(format, actual)).to eq(normalize_for(format, expected)), message
  end

  private

  def update_golden?
    ENV['UPDATE_GOLDEN'] == '1'
  end

  def golden_ext(format)
    format.to_s
  end

  def golden_path_for(format, name)
    File.expand_path("../fixtures/golden/#{name}.#{golden_ext(format)}", __dir__)
  end

  def normalize_for(format, str)
    format.to_sym == :xml ? str.rstrip : str
  end
end

RSpec.configure do |config|
  config.include GoldenHelper
end
