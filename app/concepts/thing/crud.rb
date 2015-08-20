# TODO: policy: users can only delete authors when they added them? Delete things. (chapt 9)

# EXPLAIN validation/table lock etc. later
# split up files (update goes to separate.) split up contract?
# form: presentation logic for form. (use cell?)
# talk about this? http://stackoverflow.com/questions/4116415/preselect-check-box-with-rails-simple-form

# how does skipping work: Form.new[user, user2], then validate with [user, user2:skip,user], user2 will still be there but not updated.
#   save => users = [user] (without deleted), removes user from collection.
class Thing < ActiveRecord::Base
  module SignedIn
    include Trailblazer::Operation::Module

    contract do
      property :is_author, virtual: true, default: "0"
    end

    callback(:before_save) do
      on_change :add_current_user_as_author!, property: :is_author
    end

    def add_current_user_as_author!(thing)
      # puts "@@@@@ #{thing.is_author.inspect}"
      thing.users << @current_user
    end

    def setup_params!(params) # TODO: allow passing params to callback.
      @current_user = params[:current_user]
    end
  end


  class Create < Trailblazer::Operation
    builds do |params|
      SignedIn if params[:current_user]
    end


    include CRUD#, Dispatch
    model Thing, :create

    contract do
      feature Disposable::Twin::Persisted

      property :name
      property :description

      property :file, virtual: true
      property :image_meta_data, deserializer: {writeable: false} # FIXME.

      extend Paperdragon::Model::Writer
      processable_writer :image
      validates :file, file_size: { less_than: 1.megabyte },
        file_content_type: { allow: ['image/jpeg', 'image/png'] }


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
      validate :unconfirmed_users_limit_reached?

      def unconfirmed_users_limit_reached?
        users.each do |user|
          next unless users.added.include?(user) # this covers Update, and i don't really like it here.
          next if Thing::Create::IsLimitReached.(user.model, errors)
        end
      end

    private
      def prepopulate_users!(options)
        (3 - users.size).times { users << User.new }
      end

      def populate_users!(params, options)
        User.find_by_email(params["email"]) or User.new
      end
    end

    class IsLimitReached
      def self.call(user, errors)
        return unless Tyrant::Authenticatable.new(user).confirmable?

        return if user.authorships.size == 0 && user.comments.size == 0
        errors.add("users", "User is unconfirmed and already assign to another thing or reached comment limit.")
      end
    end


    include Dispatch
    callback(:before_save) do
      on_change :upload_image!, property: :file
      collection :users do
        on_add :sign_up_sleeping!
      end
    end

    # declaratively define what happens at an event, for a nested setup.
    callback do
      collection :users do
        on_add :notify_author!
        on_add :reset_authorship!

        # on_delete :notify_deleted_author! # in Update!
      end

      on_change :expire_cache!
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
      contract.image!(contract.file) do |v|
        v.process!(:original)
        v.process!(:thumb)   { |job| job.thumb!("120x120#") }
      end
    end

    require_dependency "session/operations"
    def sign_up_sleeping!(user)
      return if user.persisted? # only new
      Session::SignUp::UnconfirmedNoPassword.(user: user.model)
    end

    def process(params)
      validate(params[:thing]) do |f|
        dispatch!(:before_save)

        f.save

        dispatch!
      end
    end

    class SignedIn < self
      include Thing::SignedIn
    end
  end




  class Update < Create
    builds do |params|
      SignedIn if params[:current_user]
    end

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


    class SignedIn < self
      include Thing::SignedIn

      module ClassMethods
        def policy(*args, &block)
          @policies = [block]
        end

        attr_reader :policies
      end
      extend ClassMethods

      def setup!(params)
        super
        instance_exec params, &self.class.policies.first or raise Pundit::NotAuthorizedError
        #
        # NotAuthorizedError.new(query: query, record: record, policy: policy)
      end

      policy do |params| # happens after #model!
        # deny! raises
        # allow!


        # do that to find it "the pundit way".
        # Pundit.policy!(params[:current_user], model)

        model.users.include?(params[:current_user])

        # authorize user, model, :update?
        # policy(@post).update?
      end
    end
  end # Update


  class Delete < Update
    def process(params)
      model.destroy
    end
  end
end

class ThingPolicy
  def update?(user, thing)
    user.owns?(thing) # FIXME: how to implement that nicely?
  end
end