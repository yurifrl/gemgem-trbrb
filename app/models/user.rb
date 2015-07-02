class User < ActiveRecord::Base
  has_many :authorships
  has_many :things, through: Authorship

  serialize :auth_meta_data
end