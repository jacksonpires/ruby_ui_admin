# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Translates framework UI strings under the `ruby_ui_admin.*` i18n namespace.
    module Translation
      def rua_t(key, **options)
        I18n.t("ruby_ui_admin.#{key}", **options)
      end
    end
  end
end
