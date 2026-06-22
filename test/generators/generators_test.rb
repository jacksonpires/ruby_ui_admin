# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "fileutils"

require "generators/ruby_ui_admin/install/install_generator"
require "generators/ruby_ui_admin/resource/resource_generator"
require "generators/ruby_ui_admin/action/action_generator"
require "generators/ruby_ui_admin/filter/filter_generator"
require "generators/ruby_ui_admin/policy/policy_generator"
require "generators/ruby_ui_admin/dashboard/dashboard_generator"
require "generators/ruby_ui_admin/card/card_generator"
require "generators/ruby_ui_admin/scope/scope_generator"
require "generators/ruby_ui_admin/eject/eject_generator"
require "generators/ruby_ui_admin/locales/locales_generator"
require "generators/ruby_ui_admin/controller/controller_generator"
require "generators/ruby_ui_admin/assets/assets_generator"
require "generators/ruby_ui_admin/components/components_generator"

GENERATOR_DESTINATION = File.expand_path("../tmp/generators", __dir__)

class ResourceGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::ResourceGenerator
  destination GENERATOR_DESTINATION

  test "generates a resource with fields derived from the model" do
    prepare_destination
    run_generator ["Comment"]

    assert_file "app/ruby_ui_admin/resources/comment.rb" do |content|
      assert_match "class Comment < RubyUIAdmin::BaseResource", content
      assert_match "field :id, as: :id", content
      # Long-form text is kept off the index by default (only on show/new/edit).
      assert_match "field :body, as: :textarea, only_on: %i[show new edit]", content
      assert_match "field :post, as: :belongs_to", content
      refute_match "field :post_id", content
    end
  end
end

class ActionGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::ActionGenerator
  destination GENERATOR_DESTINATION

  test "generates an action" do
    prepare_destination
    run_generator ["ArchivePosts"]

    assert_file "app/ruby_ui_admin/actions/archive_posts.rb" do |content|
      assert_match "class ArchivePosts < RubyUIAdmin::BaseAction", content
      assert_match 'self.name = "Archive posts"', content
      assert_match "def handle(query:, fields:, current_user:, **)", content
    end
  end

  test "supports the standalone option" do
    prepare_destination
    run_generator ["ImportThings", "--standalone"]
    assert_file "app/ruby_ui_admin/actions/import_things.rb", /self\.standalone = true/
  end
end

class FilterGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::FilterGenerator
  destination GENERATOR_DESTINATION

  test "generates a select filter" do
    prepare_destination
    run_generator ["Category", "--type", "select"]

    assert_file "app/ruby_ui_admin/filters/category_filter.rb" do |content|
      assert_match "class CategoryFilter < RubyUIAdmin::Filters::SelectFilter", content
      assert_match "def options", content
    end
  end

  test "generates a text filter by default" do
    prepare_destination
    run_generator ["Name"]
    assert_file "app/ruby_ui_admin/filters/name_filter.rb", /TextFilter/
  end
end

class PolicyGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::PolicyGenerator
  destination GENERATOR_DESTINATION

  test "generates a policy" do
    prepare_destination
    run_generator ["Post"]

    assert_file "app/ruby_ui_admin/policies/post_policy.rb" do |content|
      assert_match "class PostPolicy < RubyUIAdmin::BasePolicy", content
      assert_match "def act_on? = true", content
    end
  end
end

class DashboardGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::DashboardGenerator
  destination GENERATOR_DESTINATION

  test "generates a dashboard" do
    prepare_destination
    run_generator ["Sales"]

    assert_file "app/ruby_ui_admin/dashboards/sales.rb" do |content|
      assert_match "class Sales < RubyUIAdmin::BaseDashboard", content
      assert_match 'self.name = "Sales"', content
      assert_match "def cards", content
    end
  end
end

class CardGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::CardGenerator
  destination GENERATOR_DESTINATION

  test "generates a metric card by default" do
    prepare_destination
    run_generator ["UsersCount"]
    assert_file "app/ruby_ui_admin/cards/users_count.rb", /RubyUIAdmin::Cards::MetricCard/
  end

  test "generates a chart card" do
    prepare_destination
    run_generator ["SalesChart", "--type", "chart"]
    assert_file "app/ruby_ui_admin/cards/sales_chart.rb", /RubyUIAdmin::Cards::ChartCard/
  end
end

class ScopeGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::ScopeGenerator
  destination GENERATOR_DESTINATION

  test "generates a scope" do
    prepare_destination
    run_generator ["ActivePosts"]

    assert_file "app/ruby_ui_admin/scopes/active_posts.rb" do |content|
      assert_match "class ActivePosts < RubyUIAdmin::Scopes::BaseScope", content
      assert_match 'self.name = "Active posts"', content
      assert_match "self.scope = ->", content
    end
  end
end

class EjectGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::EjectGenerator
  destination GENERATOR_DESTINATION

  test "ejects a view component" do
    prepare_destination
    run_generator ["--view", "index"]
    assert_file "app/components/ruby_ui_admin/views/index.rb", /class Index < Base/
  end

  test "ejects the layout via the layout alias" do
    prepare_destination
    run_generator ["--view", "layout"]
    assert_file "app/components/ruby_ui_admin/views/base.rb", /class Base < Phlex::HTML/
  end

  test "ejects a controller" do
    prepare_destination
    run_generator ["--controller", "resources"]
    assert_file "app/controllers/ruby_ui_admin/resources_controller.rb", /class ResourcesController/
  end

  test "ejects a UI primitive" do
    prepare_destination
    # The admin renders the host's RubyUI primitives; the components that still ship with the
    # engine are our own compositions (Icon, Pagination, Select, Toast*).
    run_generator ["--ui", "select"]
    assert_file "app/components/ruby_ui_admin/ui/select.rb", /class Select < Base/
  end

  test "does nothing for an unknown target" do
    prepare_destination
    run_generator ["--view", "does_not_exist"]
    assert_no_file "app/components/ruby_ui_admin/views/does_not_exist.rb"
  end
end

class LocalesGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::LocalesGenerator
  destination GENERATOR_DESTINATION

  test "copies the bundled locale files" do
    prepare_destination
    run_generator

    assert_file "config/locales/ruby_ui_admin.en.yml", /ruby_ui_admin:/
    assert_file "config/locales/ruby_ui_admin.pt-BR.yml"
  end
end

class ControllerGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::ControllerGenerator
  destination GENERATOR_DESTINATION

  test "generates a per-resource controller (pluralized)" do
    prepare_destination
    run_generator ["Buyer"]

    assert_file "app/controllers/ruby_ui_admin/buyers_controller.rb" do |content|
      assert_match "class BuyersController < RubyUIAdmin::ResourcesController", content
    end
  end
end

class InstallGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::InstallGenerator
  destination GENERATOR_DESTINATION

  test "creates the initializer and mounts the engine" do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")

    run_generator

    assert_file "config/initializers/ruby_ui_admin.rb", /RubyUIAdmin\.configure/
    assert_file "config/routes.rb", /mount_ruby_ui_admin at: "\/admin"/
  end
end

class AssetsGeneratorTest < Rails::Generators::TestCase
  tests RubyUIAdmin::Generators::AssetsGenerator
  destination GENERATOR_DESTINATION

  test "bundler: copies the controllers verbatim into app/javascript/ruby_ui_admin" do
    prepare_destination

    run_generator

    # index.js plus the flat rua--* and ruby_ui--* controllers, names unchanged.
    assert_file "app/javascript/ruby_ui_admin/index.js", /application\.register\("rua--bulk-select"/
    assert_file "app/javascript/ruby_ui_admin/rua--bulk-select_controller.js"
    assert_file "app/javascript/ruby_ui_admin/ruby_ui--toaster_controller.js"
  end

  test "bundler: prints the relative import line and no pin" do
    prepare_destination

    output = run_generator

    assert_match %r{import "\./ruby_ui_admin"}, output
    refute_match "pin ", output
  end

  test "importmap: does NOT copy files, pins the engine-served (undigested) index.js" do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/importmap.rb"), "# importmap\n")

    output = run_generator

    # Copying would get digested by Propshaft and break index.js's relative imports (404).
    assert_no_file "app/javascript/ruby_ui_admin/index.js"
    assert_match %r{pin "ruby_ui_admin", to: "/ruby-ui-admin-assets/controllers/index\.js"}, output
    assert_match %r{import "ruby_ui_admin"}, output
  end
end

# Doesn't run the generator (it would shell out to ruby_ui:component); asserts the curated list,
# which is the error-prone part, and guards it against drift from the engine's actual usage.
class ComponentsGeneratorListTest < ActiveSupport::TestCase
  COMPONENTS = RubyUIAdmin::Generators::ComponentsGenerator::COMPONENTS

  test "uses the Typography group (which provides InlineLink), never a bare InlineLink" do
    assert_includes COMPONENTS, "Typography"
    refute_includes COMPONENTS, "InlineLink" # InlineLink is not a standalone RubyUI component
  end

  test "covers every RubyUI component group the engine renders" do
    engine_app = RubyUIAdmin::Engine.root.join("app")
    referenced = Dir[engine_app.join("**/*.rb")]
      .flat_map { |f| File.read(f).scan(/RubyUI::([A-Z][A-Za-z]+)/).flatten }
      .uniq

    # Rails.root is the dummy app — its ejected RubyUI mirrors a real install, so we can map each
    # referenced class to the group directory (== the name passed to ruby_ui:component) that owns it.
    dummy_ruby_ui = Rails.root.join("app/components/ruby_ui")

    missing = referenced.filter_map do |klass|
      next if klass == "Base" # RubyUI::Base comes from ruby_ui:install, not a component group

      file = Dir[dummy_ruby_ui.join("**/*.rb")].find { |f| File.read(f).match?(/class #{klass}\b/) }
      next unless file # not a grouped component we can resolve — skip

      group = Pathname.new(file).relative_path_from(dummy_ruby_ui).to_s.split("/").first
      pascal = group.split("_").map(&:capitalize).join
      pascal unless COMPONENTS.include?(pascal)
    end.uniq

    assert_empty missing, "ComponentsGenerator::COMPONENTS is missing groups the engine renders: #{missing.inspect}"
  end
end
