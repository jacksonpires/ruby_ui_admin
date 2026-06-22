# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class UrlField < BaseField
      register_as :url

      # Optional display text; defaults to the URL itself.
      def link_text(record)
        text = options[:text]
        return ExecutionContext.new(target: text, record: record, resource: resource).handle if text.respond_to?(:call)

        text || value(record)
      end

      def target
        options[:target] || "_blank"
      end
    end
  end
end
