# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Renders a field's value for index/show views, dispatching on the field type.
    class FieldValue < Phlex::HTML
      include RubyUIAdmin::UI
      include RailsHelpers
      include PathHelpers
      include Translation

      def initialize(field:, record:, link: nil)
        @field = field
        @record = record
        @link = link
      end

      def view_template
        case @field.type
        when :boolean then render_boolean
        when :belongs_to then render_belongs_to
        when :has_one then render_has_one
        when :has_many, :has_and_belongs_to_many then render_has_many
        when :record_link then render_record_link
        when :url then render_url
        when :badge then render_badge
        when :status then render_status
        when :code then render_code
        when :key_value then render_key_value
        when :boolean_group then render_boolean_group
        when :file then render_file
        when :files then render_files
        else render_text
        end
      end

      private

      def render_text
        value = @field.formatted_value(@record, view_context: view_context)
        return plain("—") if value.nil?

        # Computed blocks may return HTML (e.g. `link_to` -> html_safe); `as_html: true` opts a
        # plain string into raw rendering. Everything else is escaped.
        if (value.respond_to?(:html_safe?) && value.html_safe?) || (@field.respond_to?(:as_html?) && @field.as_html?)
          # User-rendered HTML (e.g. `link_to` in a field block) carries no admin styling.
          # The `contents` wrapper is layout-neutral and scopes `.rua-rich a` so raw links
          # underline on hover, matching the framework's own links.
          span(class: "rua-rich contents") { raw(safe(value.to_s)) }
        elsif @link && @field.link_to_record?
          render RubyUI::InlineLink.new(href: @link) { value.to_s }
        else
          plain value.to_s
        end
      end

      def render_boolean
        if @field.value(@record)
          render RubyUI::Badge.new(variant: :success) { rua_t("booleans.true") }
        else
          render RubyUI::Badge.new(variant: :gray) { rua_t("booleans.false") }
        end
      end

      def render_belongs_to
        associated = @field.value(@record)
        return plain("—") if associated.nil?

        render_record_link_to(associated, @field.display_label(associated))
      end

      def render_has_one
        associated = @field.associated_record(@record)
        return plain("—") if associated.nil?

        render_record_link_to(associated, @field.display_label(associated))
      end

      def render_has_many
        count = @field.count(@record)
        return plain("—") if count.zero?

        shown = @field.associated_records(@record, limit: 10).to_a
        # Columns come from the record's own resource (the fields must match the record's model);
        # the row link routes through `use_resource:` when given, else the record's own resource.
        column_resource = record_resource_class(shown.first)
        link_resource = (@field.respond_to?(:use_resource) && @field.use_resource) || column_resource
        columns = association_columns(column_resource)

        div(class: "space-y-2") do
          span(class: "text-xs font-medium text-muted-foreground") { rua_t("associations.count", count: count) }
          render_association_table(shown, link_resource, columns)

          if count > shown.size
            p(class: "text-xs text-muted-foreground") { rua_t("associations.more", count: count - shown.size) }
          end
        end
      end

      # Renders associated records as a RubyUI Table. When the associated model has a registered
      # resource, its index fields become the columns (Avo-style) and each row links to the
      # record's show page. Otherwise it falls back to a single column of record links.
      def render_association_table(records, resource_class, columns)
        render RubyUI::Table.new do
          if columns
            render RubyUI::TableHeader.new do
              render RubyUI::TableRow.new do
                columns.each { |field| render RubyUI::TableHead.new { field.name } }
              end
            end
          end

          render RubyUI::TableBody.new do
            records.each do |rec|
              path = association_show_path(resource_class, rec)
              attrs = if path
                {class: "cursor-pointer", data: {controller: "rua--row-link", action: "click->rua--row-link#navigate", rua__row_link_url_value: path}}
              else
                {}
              end
              render RubyUI::TableRow.new(**attrs) do
                if columns
                  columns.each_with_index do |field, index|
                    render RubyUI::TableCell.new(class: ("font-medium" if index.zero?)) do
                      link = field.link_to_record? ? path : nil
                      render RubyUIAdmin::Views::FieldValue.new(field: field, record: rec, link: link)
                    end
                  end
                else
                  render RubyUI::TableCell.new { render_record_link_to(rec, @field.display_label(rec)) }
                end
              end
            end
          end
        end
      end

      # The resource registered for a record's own model (used to build the table columns), or nil.
      def record_resource_class(record)
        return nil if record.nil?

        RubyUIAdmin.resource_manager.find_for_model(record.class)
      end

      # The columns for the association table. By default the associated resource's index fields;
      # an explicit `fields:` option on the association field picks a subset (in that order) by
      # field id — e.g. `field :suppliers, as: :has_many, fields: %i[name identifier state]`.
      # Returns nil (single-column fallback) when there's no resource or the fields can't be built.
      def association_columns(resource_class)
        return nil unless resource_class

        requested = Array(@field.options[:fields]).map(&:to_sym)
        columns =
          if requested.any?
            by_id = resource_class.new.get_fields(view: nil).index_by(&:id)
            requested.filter_map { |fid| by_id[fid] }
          else
            resource_class.new.get_fields(view: :index)
          end
        columns.presence
      rescue StandardError
        nil
      end

      def association_show_path(resource_class, record)
        return nil unless resource_class

        ruby_ui_admin.public_send("resources_#{resource_class.singular_route_key}_path", record)
      rescue StandardError
        nil
      end

      def render_record_link
        linked = @field.linked_record(@record)
        return plain("—") if linked.nil?

        target = @field.target_resource(linked)
        label = @field.display_label(linked)
        path = target && ruby_ui_admin.public_send("resources_#{target.singular_route_key}_path", linked)

        if path
          render RubyUI::InlineLink.new(href: path) { label.to_s }
        else
          plain label.to_s
        end
      end

      def render_url
        url = @field.value(@record)
        return plain("—") if url.blank?

        render RubyUI::InlineLink.new(href: url, target: @field.target) { @field.link_text(@record).to_s }
      end

      def render_badge
        value = @field.value(@record)
        return plain("—") if value.blank?

        render RubyUI::Badge.new(variant: @field.variant_for(@record)) { value.to_s }
      end

      def render_status
        value = @field.value(@record)
        return plain("—") if value.blank?

        render RubyUI::Badge.new(variant: @field.variant_for(@record)) { value.to_s }
      end

      def render_code
        value = @field.value(@record)
        lang = @field.respond_to?(:language) ? @field.language : nil
        pre(class: "rounded-md bg-muted p-3 overflow-x-auto text-xs") do
          # `language-<lang>` + data-language are the conventions syntax highlighters hook into.
          code(class: ("language-#{lang}" if lang), data: {language: lang}) { value.to_s }
        end
      end

      def render_key_value
        value = @field.value(@record)
        return plain("—") if value.blank?

        dl(class: "text-sm") do
          value.each do |key, val|
            div(class: "flex gap-2") do
              dt(class: "font-medium text-muted-foreground") { "#{key}:" }
              dd { val.to_s }
            end
          end
        end
      end

      def render_boolean_group
        div(class: "flex flex-wrap gap-1") do
          @field.group_options.each do |key, label_text|
            on = @field.checked?(@record, key)
            render RubyUI::Badge.new(variant: on ? :success : :gray) { label_text.to_s }
          end
        end
      end

      def render_file
        return plain("—") unless @field.attached?(@record)

        render_attachment(@field.attachment(@record))
      end

      def render_files
        attachments = @field.attachments(@record)
        return plain("—") if attachments.blank?

        div(class: "flex flex-col gap-2") do
          attachments.each { |attachment| render_attachment(attachment) }
        end
      end

      # An attached file: images render as a thumbnail linking to the file; everything else is a
      # download link with the filename. Both resolve the URL through the host's ActiveStorage routes.
      def render_attachment(attachment)
        blob = attachment.respond_to?(:blob) ? attachment.blob : attachment
        return plain("—") unless blob

        if blob.content_type.to_s.start_with?("image/")
          a(href: attachment_url(blob), target: "_blank", rel: "noopener", class: "inline-block") do
            img(src: attachment_url(blob), alt: blob.filename.to_s, **image_preview_attrs)
          end
        else
          a(href: attachment_url(blob, disposition: "attachment"), class: "inline-flex items-center gap-1.5 text-sm text-primary hover:underline") do
            render RubyUIAdmin::UI::Icon.new(:download, class: "size-4 shrink-0")
            plain blob.filename.to_s
          end
        end
      end

      # Thumbnail sizing. With `preview_size:` on the field, the image is capped at that W×H (px)
      # via an inline max-width/max-height (so large images scale down, preserving aspect). Inline
      # style — not a Tailwind class — because the size is dynamic and wouldn't be in the CSS build.
      def image_preview_attrs
        size = @field.respond_to?(:preview_size) ? @field.preview_size : nil
        return {class: "h-16 w-16 rounded-md border border-border object-cover"} unless size

        w, h = Array(size).first(2)
        h ||= w
        {class: "rounded-md border border-border object-contain", style: "max-width: #{w.to_i}px; max-height: #{h.to_i}px"}
      end

      # Links to a record's show page through its registered resource, if any.
      # A field's `use_resource:` overrides the default model→resource lookup.
      def render_record_link_to(record, label)
        rc = (@field.respond_to?(:use_resource) && @field.use_resource) ||
          RubyUIAdmin.resource_manager.find_for_model(record.class)

        if rc
          path = ruby_ui_admin.public_send("resources_#{rc.singular_route_key}_path", record)
          render RubyUI::InlineLink.new(href: path) { label.to_s }
        else
          plain label.to_s
        end
      end
    end
  end
end
