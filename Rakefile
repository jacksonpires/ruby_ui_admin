# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake" if File.exist?(APP_RAKEFILE)

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
  t.warning = false
end

task default: :test
