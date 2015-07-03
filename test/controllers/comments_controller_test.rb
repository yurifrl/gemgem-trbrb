require "test_helper"

require "minitest/rails/capybara"
class IntegrationTest < Capybara::Rails::TestCase
  def sign_in!(*)
    sign_up! #=> Session::SignUp

    visit "/sessions/sign_in_form"

    submit!(email="fred@trb.org", password="123456")
  end

  def sign_up!(email="fred@trb.org", password="123456")
    Session::SignUp::Admin.(user: {email: email, password: password})
  end

  def submit!(email, password)
    within("//form[@id='new_session']") do
      fill_in 'Email',    with: email
      fill_in 'Password', with: password
    end
    click_button "Sign in!"
  end
end

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
  end
end