class User::Cell < Cell::Concept
  property :email

  def show
    render
  end

private
  def email_link
    link_to email, user_path(model)
  end

  def right
    authorships
  end

  def authorships
    return unless model.authorships.size > 0

    "(#{model.authorships.count}) " +
     model.authorships.map { |as| link_to as.thing.name, thing_path(as.thing) }.join(", ")
  end
end
