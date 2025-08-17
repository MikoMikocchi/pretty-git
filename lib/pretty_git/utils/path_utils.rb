# frozen_string_literal: true

module PrettyGit
  module Utils
    # Utilities for path/glob normalization and handling cross-platform quirks.
    module PathUtils
      module_function

      # Normalize a string path or glob to Unicode NFC form.
      # Returns nil if input is nil.
      def normalize_nfc(str)
        return nil if str.nil?

        s = str.to_s
        # Only normalize if supported in this Ruby build; otherwise return as-is
        if s.respond_to?(:unicode_normalize)
          s.unicode_normalize(:nfc)
        else
          s
        end
      end

      # Normalize each entry in an Array-like collection to NFC and compact
      # nils. Returns an Array.
      def normalize_globs(collection)
        Array(collection).compact.map { |p| normalize_nfc(p) }
      end
    end
  end
end
