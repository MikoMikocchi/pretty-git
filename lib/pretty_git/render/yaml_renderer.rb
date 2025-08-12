# frozen_string_literal: true

require 'yaml'

module PrettyGit
  module Render
    # Renders full result structure as YAML
    class YamlRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(_report, result, _filters)
        # Dump the entire result structure to YAML with string keys for safe parsing
        @io.write(stringify_keys(result).to_yaml)
      end

      private

      def stringify_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), acc|
            acc[k.to_s] = stringify_keys(v)
          end
        when Array
          obj.map { |e| stringify_keys(e) }
        else
          obj
        end
      end
    end
  end
end
