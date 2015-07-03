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

  # signed in.
  it do
    sign_in!

    visit thing_path(thing.id)
    # correct page.
    page.must_have_content "Lotus"
    page.wont_have_css "#comment_user_attributes_email"

    fill_in "Your comment", with: "Tired of Rails"
    click_button "Create Comment"

    page.must_have_content "Created comment"
    page.must_have_css ".comment", text: "Tired of Rails"
  end
end