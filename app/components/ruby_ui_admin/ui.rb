# frozen_string_literal: true

require "phlex"

module RubyUIAdmin
  # Vendored RubyUI primitives, namespaced under the engine so they never collide
  # with a host app's own `RubyUI` Phlex::Kit. Visual language and
  # Tailwind classes are taken from RubyUI for consistency.
  module UI
    extend Phlex::Kit
  end
end
