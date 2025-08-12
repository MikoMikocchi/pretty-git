# frozen_string_literal: true

module PrettyGit
  module Analytics
    # Summary analytics for repository activity.
    # Aggregates totals, top authors, and top files based on streamed commits.
    class Summary
      class << self
        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        def call(enum, filters)
          totals = { commits: 0, authors: 0, additions: 0, deletions: 0 }
          per_author = Hash.new { |h, k| h[k] = { commits: 0, additions: 0, deletions: 0, email: nil } }
          per_file = Hash.new { |h, k| h[k] = { commits: 0, additions: 0, deletions: 0 } }

          enum.each do |c|
            totals[:commits] += 1
            totals[:additions] += c.additions.to_i
            totals[:deletions] += c.deletions.to_i

            key = c.author_name.to_s
            pa = per_author[key]
            pa[:email] ||= c.author_email
            pa[:commits] += 1
            pa[:additions] += c.additions.to_i
            pa[:deletions] += c.deletions.to_i

            c.files&.each do |f|
              pf = per_file[f.path]
              pf[:commits] += 1
              pf[:additions] += f.additions.to_i
              pf[:deletions] += f.deletions.to_i
            end
          end

          totals[:authors] = per_author.size

          limit = normalize_limit(filters.limit)

          top_authors = per_author.map do |name, v|
            {
              author: name,
              author_email: v[:email],
              commits: v[:commits],
              additions: v[:additions],
              deletions: v[:deletions],
              avg_commit_size: v[:commits].zero? ? 0 : ((v[:additions] + v[:deletions]).to_f / v[:commits]).round
            }
          end
          top_authors = sort_and_limit(top_authors, limit, by_path: false)

          top_files = per_file.map do |path, v|
            {
              path: path,
              commits: v[:commits],
              additions: v[:additions],
              deletions: v[:deletions],
              changes: v[:additions] + v[:deletions]
            }
          end
          top_files = sort_and_limit(top_files, limit, by_path: true)

          {
            report: 'summary',
            repo_path: File.expand_path(filters.repo_path),
            period: { since: filters.since_iso8601, until: filters.until_iso8601 },
            totals: totals,
            top_authors: top_authors,
            top_files: top_files,
            generated_at: Time.now.utc.iso8601
          }
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

        private

        def normalize_limit(raw)
          return nil if raw.nil?
          return nil if raw == 'all'

          n = raw.to_i
          n <= 0 ? nil : n
        end

        def sort_and_limit(arr, limit, by_path: false)
          sorted = arr.sort_by do |h|
            primary = by_path ? h[:changes] : (h[:additions] + h[:deletions])
            [-primary, -h[:commits], (by_path ? h[:path].to_s : h[:author].to_s)]
          end
          limit ? sorted.first(limit) : sorted
        end
      end
    end
  end
end
