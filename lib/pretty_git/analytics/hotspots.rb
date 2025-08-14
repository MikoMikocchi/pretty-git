# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Hotspots: files with the highest change activity over the selected period.
    # score = commits * (additions + deletions)
    class Hotspots
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
            commit.files&.each do |f|
              path = f.path
              unless seen[path]
                acc[path][:commits] += 1
                seen[path] = true
              end
              acc[path][:additions] += f.additions.to_i
              acc[path][:deletions] += f.deletions.to_i
            end
          end
          acc
        end

        def build_items(per_file)
          per_file.map do |path, v|
            changes = v[:additions] + v[:deletions]
            score = v[:commits] * changes
            {
              path: path,
              score: score,
              commits: v[:commits],
              additions: v[:additions],
              deletions: v[:deletions]
            }
          end
        end

        def sort_and_limit(items, raw_limit)
          limit = normalize_limit(raw_limit)
          sorted = items.sort_by { |h| [-h[:score], -h[:commits], -h[:additions] - h[:deletions], h[:path].to_s] }
          limit ? sorted.first(limit) : sorted
        end

        def build_result(filters, items)
          {
            report: 'hotspots',
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
