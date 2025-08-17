# frozen_string_literal: true

require 'open3'
require 'time'
require 'json'
require_relative '../types'
require_relative '../logger'
require_relative '../utils/path_utils'

module PrettyGit
  module Git
    # Streams commits from git CLI using `git log --numstat` and parses them.
    # rubocop:disable Metrics/ClassLength
    class Provider
      SEP_RECORD = "\x1E" # record separator
      SEP_FIELD  = "\x1F" # unit separator

      def initialize(filters)
        @filters = filters
      end

      # Returns Enumerator of PrettyGit::Types::Commit
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def each_commit
        Enumerator.new do |yld|
          prof = ENV['PG_PROF'] == '1'
          t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          headers = 0
          numstat_lines = 0
          cmd = build_git_command
          PrettyGit::Logger.verbose(
            "[pretty-git] git cmd: #{cmd.join(' ')} (cwd=#{@filters.repo_path})",
            @filters.verbose
          )
          Open3.popen3(*cmd, chdir: @filters.repo_path) do |_stdin, stdout, stderr, wait_thr|
            current = nil
            stdout.each_line do |line|
              line = line.chomp
              # Try to start a new commit from header on any line
              header = start_commit_from_header(line)
              if header
                headers += 1 if prof
                # emit previous commit if any
                emit_current(yld, current)
                current = header
                next
              end

              next if line.empty?

              numstat_lines += 1 if prof
              append_numstat_line(current, line)
            end

            emit_current(yld, current)

            status = wait_thr.value
            unless status.success?
              err = stderr.read
              raise StandardError, (err && !err.empty? ? err : "git log failed with status #{status.exitstatus}")
            end
          end

          t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          if prof
            # Emit a compact profile to stderr
            elapsed = (t1 - t0)
            warn format('[pg_prof] git_provider: time=%.3fs headers=%d numstat_lines=%d', elapsed, headers, numstat_lines)
            summary = {
              component: 'git_provider',
              time_sec: elapsed,
              headers: headers,
              numstat_lines: numstat_lines
            }
            warn("[pg_prof_json] #{summary.to_json}")
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      def emit_current(yld, current)
        return unless current

        additions = current[:files].sum(&:additions)
        deletions = current[:files].sum(&:deletions)
        commit = Types::Commit.new(
          sha: current[:sha],
          author_name: current[:author_name],
          author_email: current[:author_email],
          authored_at: current[:authored_at],
          message: current[:message],
          additions: additions,
          deletions: deletions,
          files: current[:files]
        )
        return if exclude_author?(commit.author_name, commit.author_email)

        yld << commit
      end

      def start_commit_from_header(line)
        sha, author_name, author_email, authored_at, subject = line.split(SEP_FIELD, 5)
        return nil unless subject

        {
          sha: sha,
          author_name: author_name,
          author_email: author_email,
          authored_at: Time.parse(authored_at).utc.iso8601,
          message: subject.delete(SEP_RECORD),
          files: []
        }
      end

      def append_numstat_line(current, line)
        add_s, del_s, path = line.split("\t", 3)
        return unless path

        additions = add_s == '-' ? 0 : add_s.to_i
        deletions = del_s == '-' ? 0 : del_s.to_i
        current[:files] << Types::FileStat.new(path: path, additions: additions, deletions: deletions)
      end

      def build_git_command
        args = ['git', 'log', '--no-merges', '--date=iso-strict', pretty_format_string, '--numstat']
        add_time_filters(args)
        add_author_and_branch_filters(args)
        add_path_filters(args)
        args
      end

      def pretty_format_string
        "--pretty=format:%H#{SEP_FIELD}%an#{SEP_FIELD}%ae#{SEP_FIELD}%ad#{SEP_FIELD}%s#{SEP_RECORD}"
      end

      def add_time_filters(args)
        s = @filters.since_iso8601
        u = @filters.until_iso8601
        args << "--since=#{s}" if s
        args << "--until=#{u}" if u
      end

      def add_author_and_branch_filters(args)
        @filters.authors&.each { |a| args << "--author=#{a}" }
        # Treat branches as explicit revisions to include
        @filters.branches&.each { |b| args << b }
      end

      def add_path_filters(args)
        path_args = PrettyGit::Utils::PathUtils.normalize_globs(@filters.paths)
        exclude_args = PrettyGit::Utils::PathUtils.normalize_globs(@filters.exclude_paths)

        # Nothing to filter by
        return if path_args.empty? && exclude_args.empty?

        args << '--'

        # If only excludes provided, include all paths first
        args << '.' if path_args.empty? && !exclude_args.empty?

        # Include patterns (normalized)
        args.concat(path_args) unless path_args.empty?

        # Exclude patterns via git pathspec magic with glob (normalized)
        exclude_args.each do |pat|
          args << ":(exclude,glob)#{pat}"
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def exclude_author?(name, email)
        patterns = Array(@filters.exclude_authors).compact
        return false if patterns.empty?

        patterns.any? do |pat|
          pn = pat.to_s
          name&.downcase&.include?(pn.downcase) || email&.downcase&.include?(pn.downcase)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
# rubocop:enable Metrics/ClassLength
