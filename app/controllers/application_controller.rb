class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Trailblazer::Operation::Controller
  require 'trailblazer/operation/controller/active_record'
  include Trailblazer::Operation::Controller::ActiveRecord # named instance variables.

  # include Monban::ControllerHelpers # TODO: only use signed_in, and current_user.
  # FIXME: provide by tyrant.
    def warden
      request.env['warden']
    end

    def current_user
      @current_user ||= warden.user
    end
    helper_method :current_user

    def signed_in?
      warden.user
    end
    helper_method :signed_in?


  def process_params!(params)
    params.merge!(current_user: current_user)
  end
end
