module Admin
  class UsersController < ApplicationController
    def index
      collection User::Index
    end
  end
end