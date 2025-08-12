# frozen_string_literal: true

module PrettyGit
  module Render
    # Terminal width utility functions used by console renderers/printers.
    module TerminalWidth
      module_function

      def detect_terminal_columns(io)
        return unless io.respond_to?(:tty?) && io.tty?

        cols = io_columns(io) || env_columns
        cols if cols&.positive?
      end

      def io_columns(io)
        return unless io.respond_to?(:winsize)

        io.winsize&.last
      end

      def env_columns
        ENV['COLUMNS']&.to_i
      end

      def fit_to_terminal(widths, cols)
        total = widths.sum + (widths.size - 1)
        return widths if total <= cols

        other = widths[1..].sum + (widths.size - 1)
        min_first = 8
        new_first = [cols - other, min_first].max
        widths[0] = new_first
        widths
      end
    end
  end
end
