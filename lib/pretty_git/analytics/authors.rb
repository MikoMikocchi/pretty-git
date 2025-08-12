# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Builds authors report: commits, additions, deletions, avg_commit_size
    class Authors
      class << self
        # Computes aggregates from a commits enumerator
        # Returns a Hash suitable for JSON/YAML serialization and renderers
        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        def call(commits_enum, filters)
          authors = Hash.new { |h, k| h[k] = base_author(k) }

          commits_enum.each do |c|
            key = [c.author_name, c.author_email]
            a = authors[key]
            a[:commits] += 1
            a[:additions] += c.additions
            a[:deletions] += c.deletions
          end

          rows = authors.values.map do |a|
            size = a[:additions] + a[:deletions]
            avg = a[:commits].positive? ? (size.to_f / a[:commits]).round(2) : 0.0
            a.merge(avg_commit_size: avg)
          end

          rows.sort_by! { |a| [-a[:commits], -a[:additions], a[:author]] }
          rows = rows.first(filters.limit) if filters.limit

          {
            report: 'authors',
            repo_path: filters.repo_path,
            period: { since: filters.since_iso8601, until: filters.until_iso8601 },
            totals: {
              authors: authors.length,
              commits: rows.sum { |r| r[:commits] },
              additions: rows.sum { |r| r[:additions] },
              deletions: rows.sum { |r| r[:deletions] }
            },
            items: rows,
            generated_at: Time.now.utc.iso8601
          }
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

        private

        def base_author(key)
          name, email = key
          {
            author: name,
            author_email: email,
            commits: 0,
            additions: 0,
            deletions: 0
          }
        end
      end
    end
  end
end
