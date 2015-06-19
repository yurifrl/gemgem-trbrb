require 'test_helper'

class ThingCellTest < Cell::TestCase
  controller HomeController

  let (:thing) { Thing::Create.(thing: {name: "Rails", description: "Great!!!"}).model }

  it do
    html = concept("thing/cell", thing).()
    html.must_have_selector "a", text: "Rails"
    html.must_have_content "Great!!!"
  end

end
