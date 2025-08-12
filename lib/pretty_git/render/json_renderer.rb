# frozen_string_literal: true

require 'json'

module PrettyGit
  module Render
    # Renders report result as pretty-formatted JSON to the provided IO.
    class JsonRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(_report, result, _filters)
        @io.puts JSON.pretty_generate(result)
      end
    end
  end
end
