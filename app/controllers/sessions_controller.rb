require_dependency "session/operations" # TODO: via trailblazer.

class SessionsController < ApplicationController
  def sign_up_form
    form Session::Signup
  end

  def sign_up
    run Session::Signup do |op|
      return redirect_to new_session_path
    end

    render action: :sign_up_form
  end

  def new
    form Session::Signin
  end

  # TODO: test me.
  def create
    run Session::Signin do |op|
      sign_in(op.user)
      return redirect_to root_path
    end

    render action: :new
  end

  # TODO: test me.
  alias_method :sign_out!, :sign_out
  def sign_out
    run Session::Signout do
      sign_out!
      redirect_to root_path
    end
  end

  def operation_model_name # FIXME.
   "FIXME"
  end
end