# frozen_string_literal: true

require 'yaml'

module PrettyGit
  module Render
    # Renders full result structure as YAML
    class YamlRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(report, result, _filters)
        # Apply deterministic ordering for items where applicable
        ordered = apply_order(report, result)
        # Dump the entire result structure to YAML with string keys for safe parsing
        @io.write(stringify_keys(ordered).to_yaml)
      end

      private

      def stringify_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), acc|
            acc[k.to_s] = stringify_keys(v)
          end
        when Array
          obj.map { |e| stringify_keys(e) }
        else
          obj
        end
      end

      def apply_order(report, result)
        dup = Marshal.load(Marshal.dump(result)) # deep dup
        items = dup[:items]
        return dup unless items.is_a?(Array)

        dup[:items] = case report
                       when 'hotspots'
                         items.sort_by { |r| [-to_f(r[:score]), -to_i(r[:commits]), -to_i(r[:changes]), to_s(r[:path])] }
                       when 'churn'
                         items.sort_by { |r| [-to_i(r[:churn]), -to_i(r[:commits]), to_s(r[:path])] }
                       when 'ownership'
                         items.sort_by { |r| [-to_f(r[:owner_share]), -to_i(r[:authors]), to_s(r[:path])] }
                       when 'files'
                         items.sort_by { |r| [-to_i(r[:changes]), -to_i(r[:commits]), to_s(r[:path])] }
                       when 'authors'
                         items.sort_by { |r| [-to_i(r[:commits]), -to_i(r[:additions]), -to_i(r[:deletions]), to_s(r[:author_email])] }
                       when 'languages'
                         metric = (dup[:metric] || 'bytes').to_sym
                         items.sort_by { |r| [-to_i(r[metric]), to_s(r[:language])] }
                       when 'activity'
                         items.sort_by { |r| [to_s(r[:timestamp])] }
                       when 'heatmap'
                         items.sort_by { |r| [to_i(r[:dow] || r[:day] || r[:weekday]), to_i(r[:hour])] }
                       else
                         items
                       end
        dup
      end

      def to_i(v)
        Integer(v || 0)
      rescue StandardError
        0
      end

      def to_f(v)
        Float(v || 0.0)
      rescue StandardError
        0.0
      end

      def to_s(v)
        (v || '').to_s
      end
    end
  end
end
