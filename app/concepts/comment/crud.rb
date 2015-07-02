class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD
    model Comment, :create

    contract do
      include Reform::Form::ModelReflections
      feature Disposable::Twin::Persisted

      def self.weights
        {"0" => "Nice!", "1" => "Rubbish!"}
      end

      def weights
        [self.class.weights.to_a, :first, :last]
      end


      property :body
      property :weight, prepopulator: ->(*) { self.weight = "0" }
      property :thing

      validates :body, length: { in: 6..160 }
      validates :weight, inclusion: { in: weights.keys }
      validates :thing, :user, presence: true

      property :user,
          prepopulator:      ->(*) { self.user = User.new },
          populate_if_empty: ->(*) { User.new } do
        property :email
        validates :email, presence: true, email: true
      end
    end

    callback do
      on_change :sign_up_unconfirmed!, property: :user
    end

    def process(params)
      validate(params[:comment]) do |f|
        dispatch!
        f.save # save comment and user.
      end
    end

    def thing
      model.thing
    end

  private
    def setup_model!(params)
      model.thing = Thing.find_by_id(params[:id])
    end

    require_dependency "session/operations"
    def sign_up_unconfirmed!(comment)
      Session::SignUp::UnconfirmedNoPassword.(user: comment.user.model)
    end


    class SignedIn < Create
      contract do
        property :user # TODO: allow to remove.
        validates :user, presence: :true
      end

      def sign_up_unconfirmed!(comment)
        # TODO: allow to skip.
      end
    end
  end
end

# TODO: add User unique test
