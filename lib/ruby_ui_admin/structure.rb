# frozen_string_literal: true

module RubyUIAdmin
  # Layout containers produced by the resource DSL (`panel`, `tabs`, `tab`).
  # They hold child items (fields or nested containers) for structured rendering
  # on the show/form views.
  module Structure
    class Panel
      attr_reader :name, :items

      def initialize(name = nil)
        @name = name
        @items = []
      end
    end

    class TabGroup
      attr_reader :tabs

      def initialize
        @tabs = []
      end

      # Containers expose their children through `items` for uniform traversal.
      def items
        @tabs
      end
    end

    class Tab
      attr_reader :name, :description, :items

      def initialize(name, description: nil)
        @name = name
        @description = description
        @items = []
      end
    end
  end
end
