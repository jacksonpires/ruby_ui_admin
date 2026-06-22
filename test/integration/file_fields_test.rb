# frozen_string_literal: true

require "test_helper"

# F1: file/files fields render download links on the show view, with an image thumbnail for images.
class FileFieldsTest < ActionDispatch::IntegrationTest
  test "an image file field renders a thumbnail linking to the blob" do
    acting_admin
    user = User.create!(name: "Filed", email: "filed-img@example.com")
    user.avatar.attach(io: StringIO.new("PNGDATA"), filename: "pic.png", content_type: "image/png")

    get "/admin/users/#{user.id}"

    assert_response :success
    assert_includes response.body, %(src="/rails/active_storage/blobs/redirect/) # AS path at host root
    refute_includes response.body, "/admin/rails/active_storage"                 # NOT prefixed with the engine mount
    assert_includes response.body, "<img"                                        # rendered as a thumbnail
    assert_includes response.body, %(alt="pic.png")                              # ...with the filename as alt
    assert_includes response.body, "max-width: 100px; max-height: 100px"         # capped by preview_size: 100
  end

  test "an image without preview_size uses the default thumbnail size" do
    acting_admin
    user = User.create!(name: "Def", email: "filed-defsize@example.com")
    # documents (:files) has no preview_size → default sizing
    user.documents.attach(io: StringIO.new("PNG"), filename: "img.png", content_type: "image/png")

    get "/admin/users/#{user.id}"

    assert_response :success
    assert_includes response.body, "h-16 w-16" # default thumbnail box
  end

  test "a non-image file field renders a download link with the filename" do
    acting_admin
    user = User.create!(name: "Filed", email: "filed-doc@example.com")
    user.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "report.pdf", content_type: "application/pdf")

    get "/admin/users/#{user.id}"

    assert_response :success
    assert_includes response.body, "report.pdf"             # filename shown as the link text
    assert_includes response.body, "disposition=attachment" # ...forcing a download
  end

  test "a file field with no attachment shows an em dash" do
    acting_admin
    user = User.create!(name: "Empty", email: "filed-none@example.com")

    get "/admin/users/#{user.id}"

    assert_response :success
    refute_includes response.body, "/rails/active_storage/blobs/redirect/" # nothing attached
  end

  # --- F2: edit (replace / remove) for :file ---

  test "the edit form shows the current file and a remove checkbox for an attached :file" do
    acting_admin
    user = User.create!(name: "Edit", email: "f2-edit@example.com")
    user.avatar.attach(io: StringIO.new("PNG"), filename: "old.png", content_type: "image/png")

    get "/admin/users/#{user.id}/edit"

    assert_response :success
    assert_includes response.body, "old.png"                      # current filename shown
    assert_includes response.body, %(name="record[avatar_remove]") # remove checkbox
  end

  test "checking remove purges the :file attachment" do
    acting_admin
    user = User.create!(name: "Rm", email: "f2-rm@example.com")
    user.avatar.attach(io: StringIO.new("PNG"), filename: "old.png", content_type: "image/png")

    patch "/admin/users/#{user.id}", params: {record: {avatar_remove: "1"}}

    assert_response :redirect
    assert_not user.reload.avatar.attached?
  end

  test "updating without a new file or remove keeps the existing :file" do
    acting_admin
    user = User.create!(name: "Keep", email: "f2-keep@example.com")
    user.avatar.attach(io: StringIO.new("PNG"), filename: "old.png", content_type: "image/png")

    patch "/admin/users/#{user.id}", params: {record: {name: "Renamed"}}

    assert_response :redirect
    assert user.reload.avatar.attached?
    assert_equal "old.png", user.avatar.filename.to_s
  end

  test "uploading a new file replaces the existing :file" do
    acting_admin
    user = User.create!(name: "Repl", email: "f2-repl@example.com")
    user.avatar.attach(io: StringIO.new("OLD"), filename: "old.png", content_type: "image/png")

    new_file = Rack::Test::UploadedFile.new(StringIO.new("NEW"), "image/png", original_filename: "new.png")
    patch "/admin/users/#{user.id}", params: {record: {avatar: new_file}}

    assert_response :redirect
    assert_equal "new.png", user.reload.avatar.filename.to_s
  end

  # --- F3: :files append + per-attachment remove ---

  test "the edit form lists existing :files each with a remove checkbox" do
    acting_admin
    user = User.create!(name: "F3e", email: "f3-edit@example.com")
    user.documents.attach(io: StringIO.new("A"), filename: "a.pdf", content_type: "application/pdf")
    user.documents.attach(io: StringIO.new("B"), filename: "b.pdf", content_type: "application/pdf")

    get "/admin/users/#{user.id}/edit"

    assert_response :success
    assert_includes response.body, "a.pdf"
    assert_includes response.body, "b.pdf"
    assert_includes response.body, %(name="record[documents_remove_ids][]")
  end

  test "uploading new :files appends without wiping the existing ones" do
    acting_admin
    user = User.create!(name: "F3a", email: "f3-append@example.com")
    user.documents.attach(io: StringIO.new("A"), filename: "a.pdf", content_type: "application/pdf")

    new_file = Rack::Test::UploadedFile.new(StringIO.new("C"), "application/pdf", original_filename: "c.pdf")
    patch "/admin/users/#{user.id}", params: {record: {documents: [new_file]}}

    assert_response :redirect
    names = user.reload.documents.map { |a| a.filename.to_s }
    assert_includes names, "a.pdf"
    assert_includes names, "c.pdf"
    assert_equal 2, user.documents.count
  end

  test "checking a remove id purges that :files attachment, keeping the rest" do
    acting_admin
    user = User.create!(name: "F3r", email: "f3-remove@example.com")
    user.documents.attach(io: StringIO.new("A"), filename: "a.pdf", content_type: "application/pdf")
    user.documents.attach(io: StringIO.new("B"), filename: "b.pdf", content_type: "application/pdf")
    target = user.documents.find { |a| a.filename.to_s == "a.pdf" }

    patch "/admin/users/#{user.id}", params: {record: {documents_remove_ids: [target.id.to_s]}}

    assert_response :redirect
    assert_equal ["b.pdf"], user.reload.documents.map { |a| a.filename.to_s }
  end
end
