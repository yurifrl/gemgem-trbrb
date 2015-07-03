require 'test_helper'

class HomeIntegrationTest < Capybara::Rails::TestCase
  it do
    Thing.delete_all

    Thing::Create[thing: {name: "Trailblazer"}]
    Thing::Create[thing: {name: "Descendents"}]

    visit "/"

    page.must_have_css ".columns .header a", text: "Descendents" # TODO: test not-end.
    page.must_have_css ".columns.end .header a", text: "Trailblazer"
  end
end