# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
# Rationale: this is an integration spec validating example files against schemas,
# not a spec tied to a particular class or module.

require 'spec_helper'
require 'json'
require 'json_schemer'

RSpec.describe 'JSON examples match schemas' do
  let(:base_dir) { File.expand_path('../..', __dir__) }
  let(:schemas_dir) { File.join(base_dir, 'docs', 'export_schemas', 'json') }
  let(:examples_dir) { File.join(base_dir, 'docs', 'examples', 'json') }

  def load_schema(name)
    schema_path = File.join(schemas_dir, "#{name}.schema.json")
    JSONSchemer.schema(JSON.parse(File.read(schema_path)))
  end

  # rubocop:enable RSpec/DescribeClass
  def load_example(name)
    JSON.parse(File.read(File.join(examples_dir, "#{name}.json")))
  end

  %w[hotspots churn ownership languages].each do |name|
    it "validates #{name}.json against #{name}.schema.json" do
      schemer = load_schema(name)
      data = load_example(name)
      errors = schemer.validate(data).to_a
      expect(errors).to be_empty, "Schema validation errors for #{name}: #{errors.inspect}"
    end
  end
end
