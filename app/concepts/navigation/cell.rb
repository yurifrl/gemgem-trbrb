module Navigation
  class Cell < ::Cell::Concept
    def show
      render
    end

  private
    def links
      render
    end

    def signed_in?
      model.signed_in?
    end

    def welcome_signed_in
      link_to "Hi, #{model.current_user.email}", user_path(model.current_user)
    end
  end
end
