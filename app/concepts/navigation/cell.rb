module Navigation
  # DISCUSS: Context object? or from Tyrant?
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

    def current_user
      model.current_user
    end

    def welcome_signed_in
      link_to("#{impersonate_icon} Hi, #{current_user.email}".html_safe, user_path(current_user))
    end

    def impersonate_icon
      return unless @options[:real_user]
      "<i data-tooltip class=\"fi-sheriff-badge\" title=\"You really are: #{@options[:real_user].email}\"></i>"
    end
  end
end
