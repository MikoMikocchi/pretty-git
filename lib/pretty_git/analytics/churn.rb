# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Churn: per-file volatility over the selected period.
    # churn = additions + deletions (total changed lines)
    class Churn
      class << self
        def call(enum, filters)
          per_file = aggregate(enum)
          items = build_items(per_file)
          items = sort_and_limit(items, filters.limit)
          build_result(filters, items)
        end

        private

        def aggregate(enum)
          acc = Hash.new { |h, k| h[k] = { commits: 0, additions: 0, deletions: 0 } }
          enum.each do |commit|
            seen = {}
            commit.files&.each { |f| process_file_entry(acc, seen, f) }
          end
          acc
        end

        def process_file_entry(acc, seen, file_stat)
          path = file_stat.path
          unless seen[path]
            acc[path][:commits] += 1
            seen[path] = true
          end
          acc[path][:additions] += file_stat.additions.to_i
          acc[path][:deletions] += file_stat.deletions.to_i
        end

        def build_items(per_file)
          per_file.map do |path, v|
            churn = v[:additions] + v[:deletions]
            {
              path: path,
              churn: churn,
              commits: v[:commits]
            }
          end
        end

        def sort_and_limit(items, raw_limit)
          limit = normalize_limit(raw_limit)
          sorted = items.sort_by { |h| [-h[:churn], -h[:commits], h[:path].to_s] }
          limit ? sorted.first(limit) : sorted
        end

        def build_result(filters, items)
          {
            report: 'churn',
            repo_path: File.expand_path(filters.repo_path),
            period: { since: filters.since_iso8601, until: filters.until_iso8601 },
            items: items,
            generated_at: Time.now.utc.iso8601
          }
        end

        def normalize_limit(raw)
          return nil if raw.nil? || raw == 'all'

          n = raw.to_i
          n <= 0 ? nil : n
        end
      end
    end
  end
end
