# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class DateTimeField < BaseField
      register_as :date_time

      DEFAULT_FORMAT = "%Y-%m-%d %H:%M"

      def format
        options[:format] || DEFAULT_FORMAT
      end

      def formatted_value(record, view_context: nil)
        raw = value(record, view_context: view_context)
        return nil if raw.nil?
        return super if @format_using

        # Display in the admin's configured timezone (set per-request from config.timezone).
        raw = raw.in_time_zone if raw.respond_to?(:in_time_zone)
        return raw unless raw.respond_to?(:strftime)

        fmt = options[:format]
        # A String `format:` is an explicit strftime pattern; otherwise localize via I18n.l
        # (a Symbol picks a named locale format; nil uses the gem's locale-aware default), so
        # pt-BR renders "%d/%m/%Y %H:%M", en "%Y-%m-%d %H:%M", etc.
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
