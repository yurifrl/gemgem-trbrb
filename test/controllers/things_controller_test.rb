require 'test_helper'

describe ThingsController do
  # TODO: add that to minitest-spec-rails?
  let (:page) { response.body }

  # let (:thing) { Thing::Create[thing: {name: "Trailblazer"}].model }
  let (:thing) do
    thing = Thing::Create[thing: {name: "Rails"}].model

    Comment::Create[comment: {body: "Excellent", weight: "0", user: {email: "zavan@trb.org"}}, id: thing.id]
    Comment::Create[comment: {body: "!Well.", weight: "1", user: {email: "jonny@trb.org"}}, id: thing.id]
    Comment::Create[comment: {body: "Cool stuff!", weight: "0", user: {email: "chris@trb.org"}}, id: thing.id]
    Comment::Create[comment: {body: "Improving.", weight: "1", user: {email: "hilz@trb.org"}}, id: thing.id]

    thing
  end

  describe "#new" do
    it "#new [HTML]" do
      get :new

      page.must_have_css "form #thing_name"
      page.wont_have_css "form #thing_name.readonly"

      # 3 author email fields
      page.must_have_css("input.email", count: 3) # TODO: how can i say "no value"?
    end
  end

  describe "#create" do
    it do
      post :create, {thing: {name: "Bad Religion"}}
      assert_redirected_to thing_path(Thing.last)
    end

    it do # invalid.
      post :create, {thing: {name: ""}}
      page.must_have_css ".error"

      # 3 author email fields
      page.must_have_css("input.email", count: 3)
    end
  end

  describe "#edit" do
    it do
      thing = Thing::Create[thing: {"name" => "Rails", "users" => [{"email" => "joe@trb.org"}]}].model

      get :edit, id: thing.id
      page.must_have_css "form #thing_name.readonly[value='Rails']"
      # existing email is readonly.
      page.must_have_css ".email.readonly[value='joe@trb.org']"
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
      put :update, id: thing.id, thing: {name: "Trb"}
      assert_redirected_to thing_path(thing)
      # assert_select "h1", "Trb"
    end

    it do
      put :update, id: thing.id, thing: {description: "bla"}
      page.must_have_css ".error"
    end
  end

  describe "#show" do
    it do
      get :show, id: thing.id
      response.body.must_match /Rails/

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
      post :create_comment, id: thing.id,
        comment: {body: "invalid!"}
puts @response.body
      page.must_have_css ".comment_user_email.error"
    end

    it do
      post :create_comment, id: thing.id,
        comment: {body: "That green jacket!", weight: "1", user: {email: "seuros@trb.org"}}

      assert_redirected_to thing_path(thing)
      flash[:notice].must_equal "Created comment for \"Rails\""
    end
  end

  describe "#next_comments" do
    it do
      xhr :get, :next_comments, id: thing.id, page: 2

      response.body.must_match /zavan@trb.org/
    end
  end
end