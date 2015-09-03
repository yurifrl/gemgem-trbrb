class Thing::Delete < Trailblazer::Operation
  include Resolver
  model Thing, :find
  policy Thing::Policy, :delete?

  # self.builder_class = Create.builder_class
  builds -> (model, policy, params) do
    return self::SignedIn if policy.admin?
    return self::SignedIn if policy.signed_in?
  end

  class SignedIn < self
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