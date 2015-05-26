require 'test_helper'

class ThingCrudTest < MiniTest::Spec
  describe "Create" do
    it "rendering" do # DISCUSS: not sure if that will stay here, but i like the idea of presentation/logic in one place.
      form = Thing::Create.present({}).contract
      form.prepopulate! # this is a bit of an API breach.

      form.users.size.must_equal 3 # always offer 3 user emails.
      form.users[0].email.must_equal nil
      form.users[1].email.must_equal nil
      form.users[2].email.must_equal nil
    end

    it "persists valid" do
      thing = Thing::Create[thing: {name: "Rails", description: "Kickass web dev"}].model

      thing.persisted?.must_equal true
      thing.name.must_equal "Rails"
      thing.description.must_equal "Kickass web dev"
    end

    it "invalid" do
      res, op = Thing::Create.run(thing: {name: ""})

      res.must_equal false
      op.errors.to_s.must_equal "{:name=>[\"can't be blank\"]}"
      op.model.persisted?.must_equal false
    end

    it "invalid description" do
      res, op = Thing::Create.run(thing: {name: "Rails", description: "hi"})

      res.must_equal false
      op.errors.to_s.must_equal "{:description=>[\"is too short (minimum is 4 characters)\"]}"
    end

    # users
    it "invalid email" do
      res, op = Thing::Create.run(thing: {name: "Rails", users: [{"email"=>"invalid format"}, {"email"=>"bla"}]})

      res.must_equal false
      op.errors.to_s.must_equal "{:\"users.email\"=>[\"is invalid\"]}"

      # still 3 users
      form = op.contract
      form.prepopulate! # FIXME: hate this. move prepopulate! to Op#run.

      form.users.size.must_equal 3 # always offer 3 user emails.
      form.users[0].email.must_equal "invalid format"
      form.users[1].email.must_equal "bla"
      form.users[2].email.must_equal nil # this comes from prepopulate!
    end

    it "valid, new and existing email" do
      solnic = User.create(email: "solnic@trb.org") # TODO: replace with operation, once we got one.
      User.count.must_equal 1

      model = Thing::Create.(thing: {name: "Rails", users: [{"email"=>"solnic@trb.org"}, {"email"=>"nick@trb.org"}]}).model

      model.users.size.must_equal 2
      model.users[0].attributes.slice("id", "email").must_equal("id"=>solnic.id, "email"=>"solnic@trb.org") # existing user attached to thing.
      model.users[1].email.must_equal "nick@trb.org" # new user created.
      # model.users[0].email.must_equal "invalid modelat"
      # model.users[1].email.must_equal "bla"
      # model.users[2].email.must_equal nil # this comes from prepopulate!
    end
  end

  describe "Update" do
    let (:thing) { Thing::Create[thing: {name: "Rails", description: "Kickass web dev"}].model }

    it "persists valid, ignores name" do
      Thing::Update[
        id:     thing.id,
        thing: {name: "Lotus", description: "MVC, well.."}].model

      thing.reload
      thing.name.must_equal "Rails"
      thing.description.must_equal "MVC, well.."
    end
  end
end