# frozen_string_literal: true

require 'open3'
require 'time'
require_relative '../types'

module PrettyGit
  module Git
    # Streams commits from git CLI using `git log --numstat` and parses them.
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
          cmd = build_git_command
          Open3.popen3(*cmd, chdir: @filters.repo_path) do |_stdin, stdout, stderr, wait_thr|
            current = nil
            stdout.each_line do |line|
              line = line.chomp
              # Try to start a new commit from header on any line
              header = start_commit_from_header(line)
              if header
                # emit previous commit if any
                emit_current(yld, current)
                current = header
                next
              end

              next if line.empty?

              append_numstat_line(current, line)
            end

            emit_current(yld, current)

            status = wait_thr.value
            unless status.success?
              err = stderr.read
              raise StandardError, (err && !err.empty? ? err : "git log failed with status #{status.exitstatus}")
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      def emit_current(yld, current)
        return unless current

        additions = current[:files].sum(&:additions)
        deletions = current[:files].sum(&:deletions)
        yld << Types::Commit.new(
          sha: current[:sha],
          author_name: current[:author_name],
          author_email: current[:author_email],
          authored_at: current[:authored_at],
          message: current[:message],
          additions: additions,
          deletions: deletions,
          files: current[:files]
        )
      end

      def record_separator?(line)
        line == SEP_RECORD
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
        @filters.branches&.each { |b| args << "--branches=#{b}" }
      end

      def add_path_filters(args)
        path_args = Array(@filters.paths).compact
        return if path_args.empty?

        args << '--'
        args.concat(path_args)
      end
    end
  end
end
