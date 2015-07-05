class User::Cell < Cell::Concept
  property :email

  def show
    render
  end

private
  def email_link
    link_to email, user_path(model)
  end

  def authorships
    return unless model.authorships.size > 0

    "(#{model.authorships.count}) " +
     model.authorships.map { |as| link_to as.thing.name, thing_path(as.thing) }.join(", ")
  end


  class Grid < Cell::Concept
    inherit_views User::Cell

    include ActionView::Helpers::TextHelper

    def grid
      render
    end
  end

end
