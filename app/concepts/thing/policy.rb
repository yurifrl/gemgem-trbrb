class Thing::Policy
  # def update?(user, thing)
  #   user.owns?(thing) # FIXME: how to implement that nicely?
  # end
  # def initialize(user, model, params)
    # @user, @model, @params = user, model, params
  def initialize(user, model)
    @user, @model, @params = user, model, nil
  end

  def create?
    true
  end

  # the problem here is that we need deciders to differentiate between contexts (e.g. signed_in?)
  # that we actually already know, e.g. Create::SignedIn knows it is signed in.
  def update?
    edit?
  end

  def show?
    true # FIXME: make that "configurable"
  end

  def edit?
    model.users.include?(user)
  end

  def delete?
    edit?
  end

  alias_method :call, :send # FIXME: used in @op.policy.(:show?)

private
  attr_reader :model, :user
end
