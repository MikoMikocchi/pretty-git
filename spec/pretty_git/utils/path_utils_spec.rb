# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pretty_git/utils/path_utils'

RSpec.describe PrettyGit::Utils::PathUtils do
  let(:mod) { described_class }

  it 'normalizes to NFC for single string' do
    nfd = "cafe\u0301" # 'e' + COMBINING ACUTE ACCENT
    nfc = nfd.unicode_normalize(:nfc) # single precomposed 'é'
    expect(nfd).not_to eq(nfc)

    normalized = mod.normalize_nfc(nfd)
    expect(normalized).to eq(nfc)
  end

  it 'normalizes arrays and compacts nils' do
    a = ["a\u0301.rb", nil, 'b/c']
    res = mod.normalize_globs(a)
    expect(res).to be_a(Array)
    expect(res).to include("\u00E1.rb") # "á.rb" after NFC
    expect(res).to include('b/c')
    expect(res).not_to include(nil)
  end
end
