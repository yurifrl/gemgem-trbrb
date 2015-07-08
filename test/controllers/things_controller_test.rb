require 'test_helper'

class ThingsControllerTest < IntegrationTest
  let (:thing) do
    thing = Thing::Create[thing: {name: "Rails"}].model

    Comment::Create.(comment: {body: "Excellent", weight: "0", user: {email: "zavan@trb.org"}}, id: thing.id)
    Comment::Create.(comment: {body: "!Well.", weight: "1", user: {email: "jonny@trb.org"}}, id: thing.id)
    Comment::Create.(comment: {body: "Cool stuff!", weight: "0", user: {email: "chris@trb.org"}}, id: thing.id)
    Comment::Create.(comment: {body: "Improving.", weight: "1", user: {email: "hilz@trb.org"}}, id: thing.id)

    thing
  end

  describe "#new" do
    it "#new [HTML]" do
      visit "/things/new"

      page.must_have_css "form #thing_name"
      page.wont_have_css "form #thing_name.readonly"

      # 3 author email fields
      page.must_have_css("input.email", count: 3) # TODO: how can i say "no value"?
      page.wont_have_css("#thing_is_author")
    end

    # SignedIn
    it "what" do
      sign_in!

      visit "/things/new"

      page.must_have_css "form #thing_name"
      page.wont_have_css "form #thing_name.readonly"

      # 3 author email fields
      page.must_have_css("input.email", count: 3) # TODO: how can i say "no value"?
      page.must_have_css("#thing_is_author")

      fill_in 'Name', with: "Bad Religion"
      check "I'm the author!"
      click_button "Create Thing"

      page.current_path.must_equal thing_path(Thing.last)

      page.must_have_content "By fred@trb.org"
    end
  end


  describe "#create" do
    it do
      visit "/things/new"
      fill_in 'Name', with: "Bad Religion"
      click_button "Create Thing"

      page.current_path.must_equal thing_path(Thing.last)
    end

    # TODO: better DSL for #post, etc.

    it do # invalid.
      # post :create, {thing: {name: ""}}
      visit "/things/new"
      fill_in 'Name', with: ""
      click_button "Create Thing"

      page.must_have_css ".error"

      # 3 author email fields
      page.must_have_css("input.email", count: 3)
    end
  end

  describe "#edit" do
    it do
      thing = Thing::Create[thing: {"name" => "Rails", "users" => [{"email" => "joe@trb.org"}]}].model

      visit "/things/#{thing.id}/edit"

      page.must_have_css "form #thing_name.readonly[value='Rails']"
      # existing email is readonly.
      page.must_have_css "#thing_users_attributes_0_email.readonly[value='joe@trb.org']"
      # remove button for existing.
      page.must_have_css "#thing_users_attributes_0_remove"
      # empty email for new.
      page.must_have_css "#thing_users_attributes_1_email"
      # no remove for new.
      page.wont_have_css "#thing_users_attributes_1_remove"
    end
  end

  describe "#update" do
    it do
      # put :update, id: thing.id, thing: {name: "Trb"}
      visit edit_thing_path(thing.id)
      fill_in 'Description', with: "Primitive MVC"
      click_button "Update Thing"

      # assert_redirected_to thing_path(thing)
      page.current_path.must_equal thing_path(thing.id)
      page.must_have_css "h1", text: "Rails"
      page.must_have_content "Primitive MVC"
    end

    it do
      # put :update, id: thing.id, thing: {description: "bla"}
      visit edit_thing_path(thing.id)
      fill_in 'Description', with: "bla"
      click_button "Update Thing"

      page.must_have_css ".error"
    end
  end

  describe "#show" do
    it do
      visit thing_path(thing.id)

      page.must_have_content "Rails"

       # the form. this assures the model_name is properly set.
      page.must_have_css "input.button[value=\"Create Comment\"]"
      # make sure the user form is displayed.
      page.must_have_css ".comment_user_email"
      # comments must be there.
      page.must_have_css ".comments .comment"
    end
  end

  describe "#create_comment" do
    it "invalid" do
      # post :create_comment, id: thing.id, comment: {body: "invalid!"}
      visit thing_path(thing.id)
      fill_in 'Your comment', with: "invalid!"
      click_button "Create Comment"

      page.must_have_css ".comment_user_email.error"
    end

    it do
      # post :create_comment, id: thing.id, comment: {body: "That green jacket!", weight: "1", user: {email: "seuros@trb.org"}}
      visit thing_path(thing.id)
      fill_in 'Your comment', with: "That green jacket!"
      choose "Rubbish!"
      fill_in "Your Email", with: "seuros@trb.org"
      click_button "Create Comment"

      # assert_redirected_to thing_path(thing)
      page.current_path.must_equal thing_path(thing)
      # flash[:notice].must_equal "Created comment for \"Rails\""
      page.must_have_css ".alert-box", text: "Created comment for \"Rails\""
    end
  end

  describe "#next_comments" do
    it do
      visit thing_path(thing.id)
      # xhr :get, :next_comments, id: thing.id, page: 2
      click_link "More!"

      page.must_have_content /zavan@trb.org/
    end
  end
end