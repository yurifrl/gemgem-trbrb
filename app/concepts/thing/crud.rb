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
        prepopulator: :prepopulate_users!,
        populate_if_empty: ->(params, *) { User.find_by_email(params["email"]) or User.new },
        skip_if: :all_blank do

          property :email
          validates :email, presence: true, email: true

        def readonly? # per form.
          model.persisted?
        end
      end

    private
      def prepopulate_users!(args)
        (3 - users.size).times { users << User.new }
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

      # DISCUSS: should inherit: true be default?
      collection :users, inherit: true, skip_if: :skip_user? do
        property :email#, writeable: ->(*args) { raise args.inspect } #
      end

    private
      def skip_user?(fragment, options)
        # skip when user is an existing one.
        return true if fragment["id"] # happy path. TODO: validate user add only once.
        # return true if users[index] and users[index].model.persisted?

        # replicate skip_if: :all_blank logic.
        return true if fragment["email"].blank?
      end
    end
  end
end