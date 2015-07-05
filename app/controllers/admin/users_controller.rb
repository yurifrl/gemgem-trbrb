module Admin
  class UsersController < ApplicationController
    def index
      collection User::Index

      render text: concept("user/cell/grid", @collection).(:grid), layout: true
    end
  end
end