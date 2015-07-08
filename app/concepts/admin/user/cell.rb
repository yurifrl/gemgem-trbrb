require_dependency "user/cell"

module Admin
  module User
    class Cell < ::User::Cell
      def right
        render
      end

      def thing_link(authorship)
        link_to authorship.thing.name, thing_path(authorship.thing), class: authorship.confirmed=="1" ? "confirmed" : "unconfirmed"
      end

      def checked
        "checked=1" if Tyrant::Authenticatable.new(model).confirmed?
      end
    end # Cell
  end
end