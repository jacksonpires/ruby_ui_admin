# frozen_string_literal: true

require "test_helper"

# PoC (Option 3): can the engine render the HOST's RubyUI::* components?
class RubyUIPocTest < ActiveSupport::TestCase
  test "host RubyUI::Button autoloads and renders" do
    html = RubyUI::Button.new(variant: :primary).call { "Save" }

    assert_includes html, "<button"
    assert_includes html, "bg-primary"
    assert_includes html, "Save"
  end

  test "a Phlex view (like an engine view) can embed RubyUI::Button" do
    view = Class.new(Phlex::HTML) do
      def view_template
        div(class: "wrap") { render RubyUI::Button.new(variant: :destructive) { "Delete" } }
      end
    end

    html = view.new.call
    assert_includes html, %(class="wrap")
    assert_includes html, "<button"
    assert_includes html, "Delete"
  end
end
