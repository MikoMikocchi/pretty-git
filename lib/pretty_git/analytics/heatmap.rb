# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Aggregates commits into a heatmap by day-of-week (Mon=1..Sun=7) and hour (0..23)
    class Heatmap
      class << self
        def call(enum, filters)
          grid = aggregate(enum)
          items = to_items(grid)

          {
            report: 'heatmap',
            repo_path: filters.repo_path,
            period: { since: filters.since, until: filters.until },
            items: items,
            generated_at: Time.now.utc.iso8601
          }
        end

        private

        def aggregate(enum)
          grid = Hash.new { |h, k| h[k] = Hash.new(0) } # { dow => { hour => commits } }
          enum.each { |commit| tick(grid, commit) }
          grid
        end

        def tick(grid, commit)
          t = Time.parse(commit.authored_at.to_s).utc
          dow = wday_mon1(t)
          hour = t.hour
          grid[dow][hour] += 1
        end

        def to_items(grid)
          grid.keys.sort.flat_map do |dow|
            grid[dow].keys.sort.map { |hour| { dow: dow, hour: hour, commits: grid[dow][hour] } }
          end
        end

        def wday_mon1(time)
          w = time.wday # 0..6, Sun=0
          w.zero? ? 7 : w # Mon=1..Sun=7
        end
      end
    end
  end
end
