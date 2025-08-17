# frozen_string_literal: true

module PrettyGit
  module Constants
    REPORTS = %w[
      summary activity authors files heatmap languages hotspots churn ownership
    ].freeze

    FORMATS = %w[console json csv md yaml xml].freeze

    METRICS = %w[bytes files loc].freeze

    THEMES = %w[basic bright mono].freeze
  end
end
