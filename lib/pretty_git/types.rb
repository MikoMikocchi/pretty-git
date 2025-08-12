# frozen_string_literal: true

module PrettyGit
  module Types
    Commit = Struct.new(
      :sha, :author_name, :author_email, :authored_at, :message,
      :additions, :deletions, :files, keyword_init: true
    )

    FileStat = Struct.new(:path, :additions, :deletions, keyword_init: true)

    TimeBucket = Struct.new(:key, :commits, :additions, :deletions, keyword_init: true)
  end
end
