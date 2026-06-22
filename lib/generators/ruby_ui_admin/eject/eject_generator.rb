# frozen_string_literal: true

require "rails/generators/base"

module RubyUIAdmin
  module Generators
    # Copies an engine controller / view component / UI primitive into the host app at
    # the same path. The host's copy shadows the engine's (Zeitwerk loads the app's file
    # first), so you can customize it freely.
    #
    #   rails g ruby_ui_admin:eject --view index
    #   rails g ruby_ui_admin:eject --view layout
    #   rails g ruby_ui_admin:eject --controller resources
    #   rails g ruby_ui_admin:eject --ui button
    class EjectGenerator < Rails::Generators::Base
      namespace "ruby_ui_admin:eject"
      source_root RubyUIAdmin::Engine.root.to_s

      desc "Copies an engine file into your app so you can customize it."

      class_option :controller, type: :string, desc: "Controller to eject (e.g. resources, application, actions)"
      class_option :view, type: :string, desc: "View component to eject (e.g. index, show, form, layout)"
      class_option :ui, type: :string, desc: "UI primitive to eject (e.g. button, card, table, badge)"

      def eject
        path = resolve_path
        return if path.nil?

        unless File.exist?(File.join(self.class.source_root, path))
          say "RubyUI Admin: nothing to eject at #{path}", :red
          return
        end

        copy_file path, path
        say "\nEjected #{path}. Edit it in your app to customize.", :green
      end

      private

      def resolve_path
        if options[:controller]
          "app/controllers/ruby_ui_admin/#{options[:controller]}_controller.rb"
        elsif options[:view]
          file = (options[:view] == "layout") ? "base" : options[:view]
          "app/components/ruby_ui_admin/views/#{file}.rb"
        elsif options[:ui]
          "app/components/ruby_ui_admin/ui/#{options[:ui]}.rb"
        else
          say "Specify what to eject: --controller NAME, --view NAME (or layout), or --ui NAME", :yellow
          nil
        end
      end
    end
  end
end
