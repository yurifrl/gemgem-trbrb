class User < ActiveRecord::Base
  class Index < Trailblazer::Operation
    include Collection

    def model!(params)
      User.all
    end
  end
end