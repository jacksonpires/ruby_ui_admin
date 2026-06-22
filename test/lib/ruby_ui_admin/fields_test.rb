# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class FieldsTest < ActiveSupport::TestCase
    test "select field resolves the label for a value" do
      field = Fields::SelectField.new(:status, options: {"draft" => "Draft", "live" => "Live"})
      assert_equal "Live", field.formatted_value(Struct.new(:status).new("live"))
    end

    test "badge field maps values to variants" do
      field = Fields::BadgeField.new(:status, options: {"published" => :success})
      record = Struct.new(:status).new("published")
      assert_equal :success, field.variant_for(record)
    end

    test "badge field falls back to a default variant" do
      field = Fields::BadgeField.new(:status, options: {})
      assert_equal :gray, field.variant_for(Struct.new(:status).new("x"))
    end

    test "key_value field serializes and parses JSON" do
      field = Fields::KeyValueField.new(:metadata)
      record = Struct.new(:metadata).new({"a" => 1})
      assert_includes field.value_as_json(record), "\"a\""

      target = Struct.new(:metadata).new(nil)
      field.fill_value(target, '{"b":2}')
      assert_equal({"b" => 2}, target.metadata)
    end

    test "association fields are hidden outside the show view" do
      field = Fields::HasManyField.new(:comments)
      assert field.visible_in_view?(:show)
      refute field.visible_in_view?(:index)
      refute field.visible_in_view?(:new)
    end

    test "select field derives options from an enum mapping" do
      field = Fields::SelectField.new(:status, enum: {"draft" => 0, "published" => 1})
      assert_equal [["Draft", "draft"], ["Published", "published"]], field.select_options
    end

    test "display_with_value appends the value to select labels" do
      field = Fields::SelectField.new(:status, options: {"draft" => "Draft"}, display_with_value: true)
      assert_equal [["Draft (draft)", "draft"]], field.select_options
    end

    test "visible? evaluates a lambda, defaulting to visible" do
      shown = Fields::TextField.new(:a)
      hidden = Fields::TextField.new(:b, visible: -> { false })

      assert shown.visible?
      refute hidden.visible?
    end

    test "only_on :display expands to index and show" do
      field = Fields::TextField.new(:summary, only_on: :display)
      assert field.visible_in_view?(:index)
      assert field.visible_in_view?(:show)
      refute field.visible_in_view?(:new)
      refute field.visible_in_view?(:edit)
    end

    test "only_on :forms expands to new and edit" do
      field = Fields::TextField.new(:secret, only_on: :forms)
      assert field.visible_in_view?(:new)
      assert field.visible_in_view?(:edit)
      refute field.visible_in_view?(:index)
      refute field.visible_in_view?(:show)
    end

    test "hidden field shows only on forms" do
      field = Fields::HiddenField.new(:token)
      refute field.visible_in_view?(:index)
      refute field.visible_in_view?(:show)
      assert field.visible_in_view?(:new)
    end

    test "password field never writes a blank value" do
      field = Fields::PasswordField.new(:password)
      record = Object.new
      def record.password=(_)
        raise "should not be called"
      end
      assert_nil field.fill_value(record, "")
    end
  end
end
