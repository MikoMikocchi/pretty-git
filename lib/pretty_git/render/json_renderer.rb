# frozen_string_literal: true

require 'json'

module PrettyGit
  module Render
    class JsonRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(report, result, _filters)
        @io.puts JSON.pretty_generate(result)
      end
    end
  end
end
