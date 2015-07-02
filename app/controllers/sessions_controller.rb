require_dependency "session/operations" # TODO: via trailblazer.

class SessionsController < ApplicationController
  def sign_up_form
    form Session::SignUp
  end

  def sign_up
    run Session::SignUp do |op|
      flash[:notice] = "Please log in now!"
      return redirect_to sessions_sign_in_form_path
    end

    render action: :sign_up_form
  end

  # before_filter should be used when op not involved at all.
  def sign_in_form
    form Session::SignIn
  end

  # TODO: test me.
  alias_method :sign_in!, :sign_in
  def sign_in
    run Session::SignIn do |op|
      sign_in!(op.model)
      return redirect_to root_path
    end

    render action: :sign_in_form
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