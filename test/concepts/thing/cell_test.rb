require 'test_helper'

class ThingCellTest < Cell::TestCase
  controller HomeController

  let (:thing) { Thing::Create.(thing: {name: "Rails", description: "Great!!!"}).model }

  it do
    html = concept("thing/cell", thing).()
    html.must_have_selector "a", text: "Rails"
    html.must_have_content "Great!!!"
  end


  describe "Cell::Decorator" do
    it do
      thing = Thing::Create.(thing: {name: "Rails",
        file: File.open("test/images/cells.jpg")}).model
      concept("thing/cell/decorator", thing).thumb.must_equal "<img class=\"th\" src=\"/images/thumb-cells.jpg\" alt=\"Thumb cells\" />"
    end
  end
end
