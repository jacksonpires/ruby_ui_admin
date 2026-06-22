# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class CodeField < BaseField
      register_as :code

      def language
        options[:language]
      end

      # Code can be large; keep it off the index by default.
      def default_hidden_views
        %i[index]
      end
    end
  end
end
