class Thing::Delete < Trailblazer::Operation

  module Resolver
    def self.included(includer)
      includer.class_eval do
        include Trailblazer::Operation::Policy::Pundit # ::build_policy
        include Trailblazer::Operation::CRUD::ClassBuilder # ::build_operation

        extend BuildOperation
      end
    end

    module BuildOperation
      def build_operation(params, options={})
        model  = model!(*params)
        policy = build_policy(model, *params)

        build_operation_class(model, policy, *params).new(model, options)
        # super([model, params], [model, options]) # calls: builds ->(model, params), and Op.new(model, params)
      end
    end
  end


  include Thing::Delete::Resolver # CRUD::ClassBuilder, Policy
  model Thing, :find
  policy Thing::Policy, :delete?

  # self.builder_class = Create.builder_class
  builds -> (model, policy, params) do
    return self::SignedIn if policy.admin?
    return self::SignedIn if policy.signed_in?
  end

  class SignedIn < self
    # needs: Delete CRUD config
    #        Delete #process
    #        Update::SignedIn policy
    # self.policy_class = Update::SignedIn.policy_class

    def process(params)
      model.destroy
      delete_images!
    end

  private
    def delete_images!
      Thing::ImageProcessor.new(model.image_meta_data).image! { |v| v.delete! }
    end
  end
end