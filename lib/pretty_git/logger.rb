# frozen_string_literal: true

module PrettyGit
  # Minimal centralized logger for PrettyGit.
  # Writes to stderr by default; can accept custom IO via keyword.
  module Logger
    module_function

    def warn(msg, err: $stderr)
      err.puts(msg)
    end

    # Convenience: only emit when enabled is truthy
    def verbose(msg, enabled, err: $stderr)
      return unless enabled

      warn(msg, err: err)
    end
  end
end
