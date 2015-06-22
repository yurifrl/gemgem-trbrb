# TODO: policy: users can only delete authors when they added them? Delete things. (chapt 9)

# EXPLAIN validation/table lock etc. later
# split up files (update goes to separate.) split up contract?
# form: presentation logic for form. (use cell?)
# talk about this? http://stackoverflow.com/questions/4116415/preselect-check-box-with-rails-simple-form

# how does skipping work: Form.new[user, user2], then validate with [user, user2:skip,user], user2 will still be there but not updated.
#   save => users = [user] (without deleted), removes user from collection.
class Thing < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD#, Dispatch
    model Thing, :create

    contract do
      feature Disposable::Twin::Persisted

      property :name
      property :description

      property :file, virtual: true
      property :image, virtual: true
      property :image_meta_data # FIXME.

      include Paperdragon::Model
      processable :image


      validates :name, presence: true
      validates :description, length: {in: 4..160}, allow_blank: true

      collection :users,
          prepopulator:      :prepopulate_users!,
          populate_if_empty: :populate_users!,
          skip_if:           :all_blank do

        property :email
        property :remove, virtual: true

        validates :email, presence: true, email: true
        validate :authorship_limit_reached?

        def readonly? # per form.
          model.persisted?
        end
        alias_method :removeable?, :readonly?

      private
        def authorship_limit_reached?
          return if model.authorships.find_all { |au| au.confirmed == 0 }.size < 5
          errors.add("user", "This user has too many unconfirmed authorships.")
        end
      end
      validates :users, length: {maximum: 3}

    private
      def prepopulate_users!(options)
        (3 - users.size).times { users << User.new }
      end

      def populate_users!(params, options)
        User.find_by_email(params["email"]) or User.new
      end
    end


    inheritable_attr :callbacks
    self.callbacks = {}

    def self.callback(name=:default, *args, &block)
      callbacks[name] = Class.new(Disposable::Twin::Callback::Group)
      callbacks[name].class_eval(&block)
    end
    require "disposable/twin/callback"
    def dispatch!(name=:default)
      group = self.class.callbacks[name].new(contract)
      group.(context: self)

      invocations[name] = group
    end

    def invocations
      @invocations ||= {}
    end

    callback(:upload) do
      on_change :upload_image!, property: :file
    end

    # declaratively define what happens at an event, for a nested setup.
    callback do
      collection :users do
        on_add :notify_author!
        on_add :reset_authorship!

        # on_delete :notify_deleted_author! # in Update!
      end

      # on_change :rehash_email!, property: :email

      on_create :expire_cache! # on_change
      # on_update :expire_cache!
    end

  # private
    def notify_author!(user)
      # NewUserMailer.welcome_email(user)
    end

    def reset_authorship!(user)
      user.model.authorships.find_by(thing_id: model.id).update_attribute(:confirmed, 0)
    end

    def expire_cache!(thing)
      CacheVersion.for("thing/cell/grid").expire! # of course, this is only temporary as it
      # 1. binds Op to view.
      # 2. expires cache even if thing is not part of that screen.
    end

    def upload_image!(thing)
              # raise f.image.inspect
        contract.image(contract.file) do |v|
          v.process!(:original)
          v.process!(:thumb)   { |job| job.thumb!("120x120#") }
        end
    end

    def process(params)
      validate(params[:thing]) do |f|

        dispatch!(:upload)

        f.save

        dispatch!
      end
    end

  end


  class Update < Create
    action :update
    # skip_dispatch :notify_authors!

    contract do
      property :name, writeable: false

      # DISCUSS: should inherit: true be default?
      collection :users, inherit: true, skip_if: :skip_user? do
        property :email, skip_if: :skip_email?

        def skip_email?(fragment, options)
          model.persisted?
        end
      end



      # Disposable::Twin::Callback::Runner.new(f.users).on_delete { |twin| on_remove!(twin) }

    private
      def skip_user?(fragment, options)
        # don't process if it's getting removed!
        return true if fragment["remove"] == "1" and users.delete(users.find { |u| u.id.to_s == fragment["id"] })

        # skip when user is an existing one.
        # return true if users[index] and users[index].model.persisted?

        # replicate skip_if: :all_blank logic.
        return true if fragment["email"].blank?
      end
    end
  end
end