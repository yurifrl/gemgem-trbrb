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
    authorship_links
  end

  def authorship_links
    return unless model.authorships.size > 0

    "(#{model.authorships.count}) " +
     model.authorships.map { |as| thing_link(as) }.compact.join(", ")
  end

  def thing_link(authorship)
    return unless authorship.confirmed == 1
    link_to authorship.thing.name, thing_path(authorship.thing)
  end
end
