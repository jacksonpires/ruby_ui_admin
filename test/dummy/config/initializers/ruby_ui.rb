# frozen_string_literal: true

# PoC (Option 3): wire the host-style RubyUI autoload so the engine can render
# the host's `RubyUI::*` components (ejected under app/components/ruby_ui).
module RubyUI
  extend Phlex::Kit
end

Rails.autoloaders.main.inflector.inflect("ruby_ui" => "RubyUI")
Rails.autoloaders.main.push_dir(Rails.root.join("app/components/ruby_ui"), namespace: RubyUI)
Rails.autoloaders.main.collapse(Rails.root.join("app/components/ruby_ui/*"))
