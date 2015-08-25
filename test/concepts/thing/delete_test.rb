require "test_helper"

class ThingDeleteTest < MiniTest::Spec
  it "authorless can't be deleted" do
    thing = Thing::Create.(thing: {name: "Rails"}).model

    assert_raises Pundit::NotAuthorizedError do
      Thing::Delete::SignedIn.(id: thing.id)
    end
    thing.destroyed?.must_equal false
  end

  # signed in.

  let (:current_user) { User::Create.(user: {email: "fred@trb.org"}).model }

  it "can't be deleted because we're not author" do
    thing = Thing::Create::SignedIn.(thing: {name: "Rails", users: [{"email"=>"joe@trb.org"}]}).model

    assert_raises Pundit::NotAuthorizedError do
      thing = Thing::Delete::SignedIn.(id: thing.id, current_user: current_user).model
    end
    thing.destroyed?.must_equal false
  end

  it "deleted by author, no image, no comments" do
    thing = Thing::Create::SignedIn.(thing: {name: "Rails", is_author: "1"}, current_user: current_user).model
    thing = Thing::Delete::SignedIn.(id: thing.id, current_user: current_user).model
    thing.destroyed?.must_equal true
  end

  it "deleted by author, with images and comments" do
    thing = Thing::Create::SignedIn.(thing: {name: "Rails", is_author: "1", file: File.open("test/images/cells.jpg")}, current_user: current_user).model

    file = Thing::Cell::Decorator.new(thing)

    thing = Thing::Delete::SignedIn.(id: thing.id, current_user: current_user).model
    thing.destroyed?.must_equal true

    # image must be deleted, too.
    file = Thing::Cell::Decorator.new(thing)
    File.exists?("public#{file.image[:thumb].url}").must_equal false
    File.exists?("public#{file.image[:original].url}").must_equal false
  end
end