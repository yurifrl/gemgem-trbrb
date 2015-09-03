# split up files (update goes to separate.) split up contract?
# talk about this? http://stackoverflow.com/questions/4116415/preselect-check-box-with-rails-simple-form

# how does skipping work: Form.new[user, user2], then validate with [user, user2:skip,user], user2 will still be there but not updated.
#   save => users = [user] (without deleted), removes user from collection.
require_dependency "thing/policy"
require "trailblazer/operation/policy"
require "trailblazer/operation/crud/class_builder"

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
      thing.users << @current_user
    end

    def setup_params!(params) # TODO: allow passing params to callback.
      @current_user = params[:current_user]
    end
  end


  class Create < Trailblazer::Operation
    include Trailblazer::Operation::Policy
    policy Thing::Policy, :create?
    # policy Thing, :create?, "signed_in" (can be infered from class?)
    include CRUD::ClassBuilder
    model Thing, :create

    builds -> (model, params) do
      policy = policy_config.policy(params[:current_user], model)

      return self::Admin    if policy.admin?
      return self::SignedIn if policy.signed_in?
    end



    require_dependency "thing/contract"
    self.contract_class = Contract
    contract_class.model Thing # TODO: do this automatically.



    class IsLimitReached
      def self.call(user, errors)
        return unless Tyrant::Authenticatable.new(user).confirmable?

        return if user.authorships.size == 0 && user.comments.size == 0
        errors.add("users", "User is unconfirmed and already assign to another thing or reached comment limit.")
      end
    end


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

    class Admin < self
      include Thing::SignedIn
    end
  end




  class Update < Trailblazer::Operation
    include CRUD::ClassBuilder
    model Thing, :update
    include Trailblazer::Operation::Policy
    policy Thing::Policy, :update?

    self.builder_class = Create.builder_class



    class SignedIn < Create
      include CRUD::ClassBuilder
      model Thing
      action :update



      include Thing::SignedIn
      policy Thing::Policy, :update?

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
          # replicate skip_if: :all_blank logic.
          return true if fragment["email"].blank?
        end
      end
    end # SignedIn

    class Admin < SignedIn
      contract do
        property :name
      end
    end
  end # Update

  class Show < Trailblazer::Operation
    include CRUD
    model Thing, :find

    include Trailblazer::Operation::Policy
    policy Thing::Policy, :show?
  end

  # TODO: do that in contract, too, in chapter 8.
  ImageProcessor = Struct.new(:image_meta_data) do
    extend Paperdragon::Model::Writer
    processable_writer :image
  end
end

