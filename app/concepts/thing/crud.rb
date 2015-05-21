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
        prepopulator: ->(*) { users.size == 0 ? self.users = [User.new, User.new] : users << User.new },

        populate_if_empty: ->(params, *) { User.find_by_email(params["email"]) or User.new },
        skip_if: :all_blank do

          property :email
          validates :email, presence: true, email: true
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

       collection :users, inherit: true,

# populate_if_empty: ->(params, *) { User.find_by_email(params["email"]) ? user : User.new },
        skip_if: :all_blank do
        property :email#, writeable: false

        validates :email, presence: true, email: true # FIXME: inherit properly, ya cunt!
      end

      require "pp"
      pp object_representer_class.representable_attrs
    end
  end
end