# frozen_string_literal: true

require 'rexml/document'

module PrettyGit
  module Render
    # Renders result structure as XML
    class XmlRenderer
      def initialize(io: $stdout)
        @io = io
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def call(report, result, _filters)
        ordered = apply_order(report, result)
        doc = REXML::Document.new
        doc << REXML::XMLDecl.new('1.0', 'UTF-8')
        root_name = case report
                    when 'hotspots' then 'hotspotsReport'
                    when 'churn' then 'churnReport'
                    when 'ownership' then 'ownershipReport'
                    when 'languages' then 'languagesReport'
                    when 'files' then 'filesReport'
                    when 'authors' then 'authorsReport'
                    when 'activity' then 'activityReport'
                    when 'heatmap' then 'heatmapReport'
                    else 'report'
                    end
        root = doc.add_element(root_name)
        hash_to_xml(root, ordered)
        formatter = REXML::Formatters::Pretty.new(2)
        formatter.compact = true
        formatter.write(doc, @io)
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private

      def hash_to_xml(parent, obj)
        case obj
        when Hash
          obj.each do |k, v|
            el = parent.add_element(k.to_s)
            hash_to_xml(el, v)
          end
        when Array
          obj.each do |item|
            el = parent.add_element('item')
            hash_to_xml(el, item)
          end
        else
          parent.text = obj.nil? ? '' : obj.to_s
        end
      end

      # Deterministic ordering per docs/determinism.md
      # NOTE: High branching is intentional to keep tie-breakers explicit and stable across formats.
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def apply_order(report, result)
        dup = Marshal.load(Marshal.dump(result))
        items = dup[:items]
        return dup unless items.is_a?(Array)

        dup[:items] =
          case report
          when 'hotspots'
            items.sort_by do |r|
              [-to_f(r[:score]), -to_i(r[:commits]), -to_i(r[:changes]), to_s(r[:path])]
            end
          when 'churn'
            items.sort_by { |r| [-to_i(r[:churn]), -to_i(r[:commits]), to_s(r[:path])] }
          when 'ownership'
            items.sort_by { |r| [-to_f(r[:owner_share]), -to_i(r[:authors]), to_s(r[:path])] }
          when 'files'
            items.sort_by { |r| [-to_i(r[:changes]), -to_i(r[:commits]), to_s(r[:path])] }
          when 'authors'
            items.sort_by do |r|
              [-to_i(r[:commits]), -to_i(r[:additions]), -to_i(r[:deletions]), to_s(r[:author_email])]
            end
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
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      def to_i(val)
        Integer(val || 0)
      rescue StandardError
        0
      end

      def to_f(val)
        Float(val || 0.0)
      rescue StandardError
        0.0
      end

      def to_s(val)
        (val || '').to_s
      end
    end
  end
end
