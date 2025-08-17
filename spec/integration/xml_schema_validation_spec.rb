# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass

require 'spec_helper'
require 'nokogiri'

RSpec.describe 'XML examples match XSD schemas' do
  let(:base_dir) { File.expand_path('../..', __dir__) }
  let(:schemas_dir) { File.join(base_dir, 'docs', 'export_schemas', 'xml') }
  let(:examples_dir) { File.join(base_dir, 'docs', 'examples', 'xml') }

  def load_schema(name)
    xsd_path = File.join(schemas_dir, "#{name}.xsd")
    Nokogiri::XML::Schema(File.read(xsd_path))
  end

  def load_example_doc(name)
    xml_path = File.join(examples_dir, "#{name}.xml")
    Nokogiri::XML(File.read(xml_path))
  end

  %w[hotspots churn ownership languages].each do |name|
    it "validates #{name}.xml against #{name}.xsd" do
      schema = load_schema(name)
      doc = load_example_doc(name)
      errors = schema.validate(doc)
      expect(errors).to be_empty, "XSD validation errors for #{name}: #{errors.map(&:message).join('; ')}"
    end
  end
end

# rubocop:enable RSpec/DescribeClass
