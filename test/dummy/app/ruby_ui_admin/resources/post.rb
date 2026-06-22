# frozen_string_literal: true

module RubyUIAdmin
  module Resources
    class Post < RubyUIAdmin::BaseResource
      self.title = :title
      self.includes = [:user]
      self.authorization_policy = RubyUIAdmin::Policies::PostPolicy

      # Custom buttons rendered in the index header.
      self.index_controls = -> { control_link("Invite buyer", "/admin/posts/new") }

      def actions
        action RubyUIAdmin::Actions::PublishPosts
        action RubyUIAdmin::Actions::ImportPosts
        action RubyUIAdmin::Actions::ImportPostsCsv
        action RubyUIAdmin::Actions::ArchivePosts
      end

      def filters
        filter RubyUIAdmin::Filters::StatusFilter
        filter RubyUIAdmin::Filters::TitleFilter
        filter RubyUIAdmin::Filters::PublishedFilter
        filter RubyUIAdmin::Filters::StatusesFilter
        filter RubyUIAdmin::Filters::VisibilityFilter
      end

      def scopes
        scope RubyUIAdmin::Scopes::PublishedPosts
        scope RubyUIAdmin::Scopes::DraftPosts
      end

      def fields
        field :id, as: :id

        tabs do
          tab "Content", description: "The main post content" do
            panel do
              field :title, as: :text, link_to_record: true, sortable: true, default: "Untitled", description: "The post headline"
              field :body, as: :textarea, only_on: %i[show new edit]
              # Conditional visibility: only admins see this computed column.
              field :admin_note, as: :text, only_on: :index, visible: -> { current_user&.admin? } do
                "admin-only-#{record.id}"
              end
              field :status, as: :badge, options: {"draft" => :warning, "published" => :success, "archived" => :gray}
              field :published, as: :boolean
              field :homepage, as: :url, only_on: %i[show new edit]
            end
          end

          tab "Details" do
            # Custom sort: ordering by "views_count" actually orders by title.
            field :views_count, as: :number, sortable: -> { query.reorder(title: direction) }
            field :published_on, as: :date, only_on: %i[show new edit]
            field :metadata, as: :key_value, only_on: %i[show new edit]
            field :flags, as: :boolean_group, options: {"beta" => "Beta program", "pro" => "Pro features"}, only_on: %i[show new edit]
            field :user, as: :belongs_to
            # `fields:` limits the association table columns (and orders them) by field id.
            field :comments, as: :has_many, fields: %i[body created_at]

            # for_attribute (reads :comments) + scope (only "keep" bodies) + use_resource
            # (links through the Post resource to make the override observable).
            field :discussion, as: :has_many, only_on: :show,
              for_attribute: :comments,
              scope: -> { query.where("body LIKE ?", "%keep%") },
              use_resource: RubyUIAdmin::Resources::Post
            field :created_at, as: :date_time, only_on: %i[index show]

            # Computed block using view/url helpers + current_user; returns HTML (link_to).
            field :quick_link, as: :text, only_on: :display do
              link_to("Open #{record.title}", ruby_ui_admin.resources_posts_path) if current_user
            end

            # Plain-string block opted into raw rendering via as_html.
            field :status_html, as: :text, as_html: true, only_on: :show do
              "<em data-test=\"status-html\">#{record.status}</em>"
            end

            # Code field with a syntax-highlight language.
            field :snippet, as: :code, language: "ruby", only_on: :show do
              "puts #{record.id}"
            end

            # G27: visible lambda using the `view` predicate object (view.show?).
            field :show_note, as: :text, only_on: :display, visible: -> { view.show? } do
              "note-on-show-#{record.id}"
            end

            # G28: select options lambda reading request params.
            field :pick, as: :select, only_on: %i[new edit],
              options: -> { params[:pick_from].to_s.split(",").map { |p| [p.capitalize, p] } }
          end
        end
      end
    end
  end
end
