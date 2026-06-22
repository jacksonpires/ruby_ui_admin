# frozen_string_literal: true

require "fileutils"

namespace :ruby_ui_admin do
  desc "Print the installed RubyUI Admin version"
  task :version do
    require "ruby_ui_admin/version"
    puts "RubyUI Admin #{RubyUIAdmin::VERSION}"
  end

  desc "Compile the engine's bundled Tailwind stylesheet (gem development)"
  task :build_assets do
    require "tailwindcss/ruby"

    root = File.expand_path("../..", __dir__)
    input = File.join(root, "app/assets/stylesheets/ruby_ui_admin/application.tailwind.css")
    output = File.join(root, "public/ruby-ui-admin-assets/application.css")

    FileUtils.mkdir_p(File.dirname(output))

    ok = system(Tailwindcss::Ruby.executable, "-i", input, "-o", output, "--minify")
    abort("RubyUI Admin: Tailwind build failed") unless ok

    puts "RubyUI Admin: built #{output}"
  rescue LoadError
    abort("RubyUI Admin: tailwindcss-ruby is required to build assets (add it to your dev dependencies).")
  end

  desc "Install RubyUI Admin (creates the initializer and mounts the engine)"
  task install: :environment do
    system(RbConfig.ruby, "bin/rails", "generate", "ruby_ui_admin:install")
  end

  desc "Generate resources for every ActiveRecord model"
  task all_resources: :environment do
    Rails.application.eager_load!

    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?
      next unless model.name

      system(RbConfig.ruby, "bin/rails", "generate", "ruby_ui_admin:resource", model.name)
    end
  end

  desc "Extract the admin's Tailwind classes into the host app (writes a file to @source)"
  task :tailwind_source, [:path] => :environment do |_task, args|
    require "ruby_ui_admin/tailwind_source"

    default = Rails.root.join("app/assets/tailwind/ruby_ui_admin_classes.html")
    dest = args[:path] ? File.expand_path(args[:path], Rails.root) : default.to_s
    RubyUIAdmin::TailwindSource.write(dest)

    rel = Pathname.new(dest).relative_path_from(Rails.root.join("app/assets/tailwind")).to_s
    rel = "./#{rel}" unless rel.start_with?(".")

    puts "RubyUI Admin: wrote #{dest}"
    puts "Add this to your Tailwind entry CSS (e.g. app/assets/tailwind/application.css) and commit"
    puts "the generated file; re-run this task after upgrading the gem:"
    puts %(  @source "#{rel}";)
  end

  desc "List the mounted admin routes"
  task routes: :environment do
    RubyUIAdmin::Engine.routes.routes.each do |route|
      verb = route.verb.is_a?(String) ? route.verb : route.verb.source.gsub(/[$^]/, "")
      puts "#{verb.ljust(7)} #{route.path.spec}"
    end
  end
end
