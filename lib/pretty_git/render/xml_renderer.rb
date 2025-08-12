# frozen_string_literal: true

require 'rexml/document'

module PrettyGit
  module Render
    # Renders result structure as XML
    class XmlRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(_report, result, _filters)
        doc = REXML::Document.new
        doc << REXML::XMLDecl.new('1.0', 'UTF-8')
        root = doc.add_element('report')
        hash_to_xml(root, result)
        formatter = REXML::Formatters::Pretty.new(2)
        formatter.compact = true
        formatter.write(doc, @io)
      end

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
    end
  end
end
