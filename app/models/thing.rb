class Thing < ActiveRecord::Base
  has_many :comments, -> { order(created_at: :desc) }
  has_many :users, through: :authorships
  has_many :authorships

  scope :latest, lambda { all.limit(9).order("id DESC") }


  include Paperdragon::Model
  processable :image # this is only for image[:thumb], move to twin.
  serialize :image_meta_data
end
