# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class DateField < BaseField
      register_as :date

      DEFAULT_FORMAT = "%Y-%m-%d"

      def format
        options[:format] || DEFAULT_FORMAT
      end

      def formatted_value(record, view_context: nil)
        raw = value(record, view_context: view_context)
        return nil if raw.nil?
        return super if @format_using
        return raw unless raw.respond_to?(:strftime)

        fmt = options[:format]
        # A String `format:` is an explicit strftime pattern; otherwise localize via I18n.l
        # (Symbol = named locale format, nil = gem's locale-aware default) so pt-BR renders
        # "%d/%m/%Y", en "%Y-%m-%d", etc.
        return raw.strftime(fmt) if fmt.is_a?(String)

        begin
          I18n.l(raw, format: fmt || :ruby_ui_admin)
        rescue
          raw.strftime(DEFAULT_FORMAT)
        end
      end
    end
  end
end
