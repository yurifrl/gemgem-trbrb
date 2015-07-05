module Admin
  module User
    class Cell < ::User::Cell


      def right
        render
      end

      def authorships
        return unless model.authorships.size > 0

        "(#{model.authorships.count}) " +
         model.authorships.map { |as| link_to as.thing.name, thing_path(as.thing) }.join(", ")
      end

      def confirmed?
        puts "@@@@@ #{Session::Authenticatable.new(model).confirmed?.inspect}"
        Session::Authenticatable.new(model).confirmed?
      end
      def checked
        return "checked=1" if confirmed?
""
      end
    end # Cell
  end
end