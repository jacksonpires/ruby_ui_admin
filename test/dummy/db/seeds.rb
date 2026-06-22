# frozen_string_literal: true

# Demo data for browsing the admin (bin/rails db:seed). Idempotent: clears first
# (FK-safe order; the habtm join and attachments are cleared before their parents).
ActiveRecord::Base.connection.execute("DELETE FROM tags_users")
ActiveStorage::Attachment.delete_all
ActiveStorage::Blob.delete_all
[Comment, Post, Profile, Tag, User].each(&:delete_all)

tags = %w[ruby rails phlex tailwind admin design api testing ci docs ux perf security mobile web]
       .map { |name| Tag.create!(name: name) }

admin = User.create!(
  name: "Ada Admin", email: "admin@example.com", admin: true, role: "admin",
  state: "active", bio: "Runs the show.", birthday: Date.new(1990, 5, 1)
)
editor = User.create!(
  name: "Eddy Editor", email: "editor@example.com", role: "editor",
  state: "pending", bio: "Edits posts.", birthday: Date.new(1992, 8, 12)
)
viewer = User.create!(
  name: "Vic Viewer", email: "viewer@example.com", role: "viewer",
  state: "blocked", birthday: Date.new(1995, 1, 30)
)

admin.tags  = tags.sample(4)
editor.tags = tags.sample(3)
Profile.create!(user: admin, headline: "Founder", bio: "Building things.")
Profile.create!(user: editor, headline: "Wordsmith")

statuses = %w[draft published archived]
20.times do |i|
  author = [admin, editor, viewer].sample
  status = statuses.sample
  post = Post.create!(
    title: "Sample Post #{i + 1}",
    body: "Body of post #{i + 1}.",
    status: status,
    published: status == "published",
    views_count: rand(0..500),
    published_on: (status == "published" ? Date.today - rand(0..60) : nil),
    homepage: "https://example.com/posts/#{i + 1}",
    metadata: {"source" => "seed", "index" => i + 1},
    flags: {"beta" => i.even?, "pro" => i.odd?},
    user: author
  )

  rand(0..3).times do |c|
    body = c.zero? ? "keep this comment #{c}" : "drop comment #{c}"
    post.comments.create!(body: body)
  end
end

puts "Seeded: #{User.count} users, #{Tag.count} tags, #{Profile.count} profiles, " \
     "#{Post.count} posts, #{Comment.count} comments."
