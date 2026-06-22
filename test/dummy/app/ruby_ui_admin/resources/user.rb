# frozen_string_literal: true

module RubyUIAdmin
  module Resources
    # Kitchen-sink resource: exercises the field types not covered by Post
    # (select, status, password, hidden, date, file, files, has_one, habtm) plus
    # resource-level row controls.
    class User < RubyUIAdmin::BaseResource
      self.title = :email
      self.description = "Application users, their access and attachments."

      # Per-row controls + their layout.
      self.row_controls = ->(record) { show_button(record, label: "Open") }
      self.row_controls_config = {placement: :right, show_on_hover: true}

      def fields
        field :id, as: :id

        tabs do
          tab "Account", description: "Identity and access." do
            panel do
              field :name, as: :text, link_to_record: true, sortable: true
              field :email, as: :text, default: -> { current_user&.email }, description: "Login email"
              field :role, as: :select, display_with_value: true,
                options: {"admin" => "Administrator", "editor" => "Editor", "viewer" => "Viewer"}
              field :state, as: :status,
                options: {success: %w[active], warning: %w[pending], danger: %w[blocked]}
              field :admin, as: :boolean
            end
          end

          tab "Details", description: "Profile content and credentials." do
            field :bio, as: :textarea, only_on: %i[show new edit]
            field :birthday, as: :date
            field :secret, as: :password, help: "Write-only; never displayed."
            field :token, as: :hidden
            field :avatar, as: :file, accept: "image/*", preview_size: 100
            field :documents, as: :files
          end

          tab "Associations" do
            field :profile, as: :has_one
            field :tags, as: :has_and_belongs_to_many
            field :posts, as: :has_many
            field :created_at, as: :date_time, only_on: %i[index show]
          end
        end
      end
    end
  end
end
