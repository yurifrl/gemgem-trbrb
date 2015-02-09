class Thing < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD
    model Thing, :create

    contract do
      property :name
      property :description

      validates :name, presence: true
      validates :description, length: {in: 4..160}, allow_blank: true

      collection :users,
        # prepopulate: ->(*) { [User.new, User.new] },
        populate_if_empty: ->(params, *) { (user = User.find_by_email(params["email"])) ? user : User.new },
        skip_if: :all_blank do
          property :email
          validates :email, presence: true, email: true
      end

      def users
        return [User.new, User.new] if super.blank? # here, i offer one form to enter an author.
        super # user fields were submitted.
      end
    end

    def process(params)
      validate(params[:thing]) do |f|
        f.save
      end
    end
  end

  class Update < Create
    action :update

    contract do
      property :name, writeable: false
    end
  end
end