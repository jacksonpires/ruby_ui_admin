# frozen_string_literal: true

require "rails/generators/base"

module RubyUIAdmin
  module Generators
    # Copies the bundled locale files into the host app so they can be edited/extended.
    class LocalesGenerator < Rails::Generators::Base
      namespace "ruby_ui_admin:locales"
      source_root RubyUIAdmin::Engine.root.to_s

      desc "Copies RubyUI Admin's locale files into config/locales."

      def copy_locales
        Dir[File.join(self.class.source_root, "config", "locales", "*.yml")].each do |file|
          relative = File.join("config", "locales", File.basename(file))
          copy_file relative, relative
        end
      end
    end
  end
end
