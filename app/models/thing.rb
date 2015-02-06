class Thing < ActiveRecord::Base
  has_many :comments, -> { order(created_at: :desc) }
  has_and_belongs_to_many :users

  scope :latest, lambda { all.limit(9).order("id DESC") }
end
