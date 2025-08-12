# frozen_string_literal: true

module PrettyGit
  module Analytics
    # Files analytics: aggregates by file path across commits
    class Files
      class << self
        def call(enum, filters)
          per_file = aggregate_per_file(enum)
          limit = normalize_limit(filters.limit)
          items = build_items(per_file)
          items = sort_and_limit(items, limit)
          build_result(filters, items)
        end

        private

        def aggregate_per_file(enum)
          per_file = Hash.new { |h, k| h[k] = { commits: 0, additions: 0, deletions: 0 } }
          enum.each do |c|
            seen_paths = {}
            c.files&.each { |f| process_file_entry(per_file, seen_paths, f) }
          end
          per_file
        end

        def process_file_entry(per_file, seen_paths, file_stat)
          path = file_stat.path
          unless seen_paths[path]
            per_file[path][:commits] += 1
            seen_paths[path] = true
          end
          per_file[path][:additions] += file_stat.additions.to_i
          per_file[path][:deletions] += file_stat.deletions.to_i
        end

        def build_items(per_file)
          per_file.map do |path, v|
            {
              path: path,
              commits: v[:commits],
              additions: v[:additions],
              deletions: v[:deletions],
              changes: v[:additions] + v[:deletions]
            }
          end
        end

        def build_result(filters, items)
          {
            report: 'files',
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

        def sort_and_limit(arr, limit)
          sorted = arr.sort_by { |h| [-h[:changes], -h[:commits], h[:path].to_s] }
          limit ? sorted.first(limit) : sorted
        end
      end
    end
  end
end
