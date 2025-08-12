# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Activity analytics: buckets commits by day/week/month.
    class Activity
      class << self
        def call(enum, filters)
          bucket = (filters.time_bucket || 'week').to_s
          groups = aggregate(enum, bucket)
          items = groups_to_items(groups, bucket)
          build_result(filters, bucket, items)
        end

        private

        def aggregate(enum, bucket)
          groups = Hash.new { |h, k| h[k] = { commits: 0, additions: 0, deletions: 0 } }
          enum.each { |c| process_commit(groups, bucket, c) }
          groups
        end

        def process_commit(groups, bucket, commit)
          ts = Time.parse(commit.authored_at.to_s).utc
          key_time = bucket_start(ts, bucket)
          g = groups[key_time]
          g[:commits] += 1
          g[:additions] += commit.additions.to_i
          g[:deletions] += commit.deletions.to_i
        end

        def groups_to_items(groups, bucket)
          groups.keys.sort.map do |t|
            v = groups[t]
            {
              bucket: bucket,
              timestamp: t.utc.iso8601,
              commits: v[:commits],
              additions: v[:additions],
              deletions: v[:deletions]
            }
          end
        end

        def build_result(filters, bucket, items)
          {
            report: 'activity',
            repo_path: File.expand_path(filters.repo_path),
            period: { since: filters.since_iso8601, until: filters.until_iso8601 },
            bucket: bucket,
            items: items,
            generated_at: Time.now.utc.iso8601
          }
        end

        def bucket_start(time, bucket)
          return start_of_iso_week(time) if bucket == 'week'
          return start_of_month(time) if bucket == 'month'

          start_of_day(time)
        end

        def start_of_day(time)
          Time.utc(time.year, time.month, time.day)
        end

        def start_of_iso_week(time)
          # ISO week starts on Monday. Find Monday of the current week at 00:00 UTC.
          wday = (time.wday + 6) % 7 # Monday=0 .. Sunday=6
          base = time - (wday * 86_400)
          Time.utc(base.year, base.month, base.day)
        end

        def start_of_month(time)
          Time.utc(time.year, time.month, 1)
        end
      end
    end
  end
end
