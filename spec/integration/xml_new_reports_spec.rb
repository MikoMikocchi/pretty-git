# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'nokogiri'
require_relative '../../lib/pretty_git/render/xml_renderer'

RSpec.describe PrettyGit::Render::XmlRenderer do
  let(:io) { StringIO.new }
  let(:renderer) { described_class.new(io: io) }

  def render(report, items)
    io.truncate(0)
    io.rewind
    renderer.call(report, { report: report, items: items }, nil)
    Nokogiri::XML(io.string)
  end

  it 'is deterministic for churn regardless of input item order' do
    a = [{ path: 'a.rb', churn: 1, commits: 1, additions: 1, deletions: 0 },
         { path: 'b.rb', churn: 3, commits: 2, additions: 2, deletions: 1 }]
    b = a.reverse

    xa = render('churn', a)
    xb = render('churn', b)

    pa = xa.xpath('//report/items/item/path').map(&:text)
    pb = xb.xpath('//report/items/item/path').map(&:text)

    expect(pa).to eq(%w[b.rb a.rb])
    expect(xa.to_xml).to eq(xb.to_xml)
  end

  it 'renders ownership fields' do
    doc = render('ownership', [{ path: 'a.rb', owner: 'A', owner_share: 60.0, authors: 2 }])
    item = doc.at_xpath('//report/items/item')
    expect(item.at_xpath('./path').text).to eq('a.rb')
    expect(item.at_xpath('./owner').text).to eq('A')
    expect(item.at_xpath('./owner_share').text).to eq('60.0')
    expect(item.at_xpath('./authors').text).to eq('2')
  end
end
