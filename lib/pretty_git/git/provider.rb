# frozen_string_literal: true

require 'open3'
require 'time'
require_relative '../types'

module PrettyGit
  module Git
    class Provider
      SEP_RECORD = "\x1E" # record separator
      SEP_FIELD  = "\x1F" # unit separator

      def initialize(filters)
        @filters = filters
      end

      # Returns Enumerator of PrettyGit::Types::Commit
      def each_commit
        enum = Enumerator.new do |y|
          cmd = build_git_command
          Open3.popen3(*cmd, chdir: @filters.repo_path) do |_stdin, stdout, stderr, wait_thr|
            current = nil
            stdout.each_line do |line|
              line = line.chomp
              if line == SEP_RECORD
                emit_current(y, current)
                current = nil
                next
              end

              # Header line with fields separated by SEP_FIELD
              if current.nil?
                sha, author_name, author_email, authored_at, subject = line.split(SEP_FIELD, 5)
                current = {
                  sha: sha,
                  author_name: author_name,
                  author_email: author_email,
                  authored_at: Time.parse(authored_at).utc.iso8601,
                  message: subject,
                  files: [],
                }
                next
              end

              # numstat or blank splitter between commits
              if line.empty?
                next
              end

              add_s, del_s, path = line.split("\t", 3)
              # skip if not a numstat line
              next unless path

              additions = add_s == '-' ? 0 : add_s.to_i
              deletions = del_s == '-' ? 0 : del_s.to_i
              current[:files] << Types::FileStat.new(path: path, additions: additions, deletions: deletions)
            end

            emit_current(y, current)

            status = wait_thr.value
            unless status.success?
              err = stderr.read
              raise StandardError, (err && !err.empty? ? err : "git log failed with status #{status.exitstatus}")
            end
          end
        end
        enum
      end

      private

      def emit_current(y, current)
        return unless current
        additions = current[:files].sum(&:additions)
        deletions = current[:files].sum(&:deletions)
        y << Types::Commit.new(
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

      def build_git_command
        args = [
          'git', 'log', '--no-merges', '--date=iso-strict',
          "--pretty=format:%H#{SEP_FIELD}%an#{SEP_FIELD}%ae#{SEP_FIELD}%ad#{SEP_FIELD}%s#{SEP_RECORD}",
          '--numstat'
        ]

        if (s = @filters.since_iso8601)
          args << "--since=#{s}"
        end
        if (u = @filters.until_iso8601)
          args << "--until=#{u}"
        end

        @filters.authors&.each { |a| args << "--author=#{a}" }
        # branches: if provided, add --branches=<name> for each; else use current HEAD implicitly
        @filters.branches&.each { |b| args << "--branches=#{b}" }

        # Paths include: add separator and globs
        path_args = Array(@filters.paths).compact
        unless path_args.empty?
          args << '--'
          args.concat(path_args)
        end

        args
      end
    end
  end
end
