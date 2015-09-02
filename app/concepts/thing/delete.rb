class Thing::Delete < Trailblazer::Operation
  include CRUD::ClassBuilder
  model Thing, :find

  include Trailblazer::Operation::Policy::Pundit
  policy Thing::Policy, :delete?

  # self.builder_class = Create.builder_class
  builds -> (model, params) do
    policy = build_policy(model, params)

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