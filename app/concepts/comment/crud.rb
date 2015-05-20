class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD
    model Comment, :create

    contract do
      include Reform::Form::ModelReflections

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

      require "reform/form/validation/unique_validator.rb"
      property :user do
        property :email
        validates :email, presence: true, email: true, unique: true
      end
    end

    require "active_record/locking/fatalistic"
    def process(params)
      validate(params[:comment]) do |f|
        f.save # save comment and user.
      end
    end

    def thing
      model.thing
    end

  private
    def setup_model!(params)
      model.thing = Thing.find_by_id(params[:id])
      model.build_user
    end
  end
end

# TODO: add User unique test