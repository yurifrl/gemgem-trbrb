require "test_helper"

class CommentsControllerIntegrationTest < IntegrationTest
  let (:thing) { Thing::Create.(thing: {name: "Lotus"}).model }

  # comment form, not signed in.
  it do
    visit thing_path(thing.id)
    # correct page.
    page.must_have_content "Lotus"

    # allows unregistered comment.
    page.must_have_css "#comment_user_attributes_email"
  end

  it do
    sign_up!

    visit thing_path(thing.id)
    # correct page.
    page.must_have_content "Lotus"

  end
end