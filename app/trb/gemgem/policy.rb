module Gemgem
  module Policy # DISCUSS: could also be class.
    def admin_for?(user)
      user.email == "admin@trb.org"
    end

    def signed_in?
      user.present?
    end
  end
end