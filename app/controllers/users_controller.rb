class UsersController < ApplicationController
  def index
    collection User::Index

    @cell = "user/cell"
    @cell = "admin/user/cell" if params[:admin]
  end
end