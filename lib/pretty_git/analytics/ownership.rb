# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Ownership: per-file code ownership based on change activity (churn).
    # For each file, the owner is the author with the largest share of churn (adds+dels).
    class Ownership
      class << self
        def call(enum, filters)
          per_file = aggregate(enum)
          items = build_items(per_file)
          items = sort_and_limit(items, filters.limit)
          build_result(filters, items)
        end

        private

        # Builds a map: path => { total_churn: N, authors: {"name <email>" => churn} }
        def aggregate(enum)
          acc = Hash.new { |h, k| h[k] = { total: 0, authors: Hash.new(0) } }
          enum.each do |commit|
            author_key = author_identity(commit)
            commit.files&.each { |f| process_file_entry(acc, author_key, f) }
          end
          acc
        end

        def process_file_entry(acc, author_key, file_stat)
          churn = file_stat.additions.to_i + file_stat.deletions.to_i
          return if churn <= 0

          path = file_stat.path
          acc[path][:total] += churn
          acc[path][:authors][author_key] += churn
        end

        def author_identity(commit)
          name = commit.author_name.to_s.strip
          email = commit.author_email.to_s.strip
          email.empty? ? name : "#{name} <#{email}>"
        end

        def build_items(per_file)
          per_file.map do |path, v|
            owner, share, authors_count = compute_owner(v[:authors], v[:total])
            {
              path: path,
              owner: owner,
              owner_share: share.round(2),
              authors: authors_count
            }
          end
        end

        def compute_owner(authors_map, total)
          return [nil, 0.0, 0] if total.to_i <= 0 || authors_map.nil? || authors_map.empty?

          author, owner_churn = authors_map.max_by { |a, c| [c, a] }
          share = (owner_churn.to_f * 100.0) / total.to_f
          [author, share, authors_map.size]
        end

        def sort_and_limit(items, raw_limit)
          limit = normalize_limit(raw_limit)
          sorted = items.sort_by { |h| [-h[:owner_share].to_f, h[:authors].to_i, h[:path].to_s] }
          limit ? sorted.first(limit) : sorted
        end

        def build_result(filters, items)
          {
            report: 'ownership',
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
