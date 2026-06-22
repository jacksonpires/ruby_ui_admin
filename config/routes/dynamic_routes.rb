# frozen_string_literal: true

# Draws RESTful routes for every registered resource, e.g.:
#   resources_posts_path, new_resources_post_path, edit_resources_post_path, ...
# The generic ResourcesController reads params[:resource_name] to resolve the resource.
RubyUIAdmin.resource_manager.resources.each do |resource|
  resources resource.route_key,
    controller: RubyUIAdmin.controller_for(resource),
    as: "resources_#{resource.route_key}",
    defaults: {resource_name: resource.route_key}
end
