# TODO: policy: users can only delete authors when they added them? Delete things. (chapt 9)
# TODO: make :populate_if_empty dynamic (allow instance methods).
class Thing < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD, Dispatch
    model Thing, :create

    contract do
      property :name
      property :description

      validates :name, presence: true
      validates :description, length: {in: 4..160}, allow_blank: true

      collection :users,
        # prepopulate: ->(*) { users.size == 0 ? [User.new, User.new] : [User.new] },
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

        dispatch :notify_authors!
      end
    end

  private
    def notify_authors!
      # TODO: mark new authors and send mails only to those.
      model.users.collect { |user| NewUserMailer.welcome_email(user) }
    end
  end

  class Update < Create
    action :update
    skip_dispatch :notify_authors!

    contract do
      property :name, writeable: false

      collection :users, inherit: true do
        property :email, writeable: false
      end
    end
  end
end