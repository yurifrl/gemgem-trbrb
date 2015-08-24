class Thing::Create::Contract < Reform::Form
  feature Disposable::Twin::Persisted

  property :name
  property :description

  property :file, virtual: true
  property :image_meta_data, deserializer: {writeable: false} # FIXME.

  extend Paperdragon::Model::Writer
  processable_writer :image
  validates :file, file_size: { less_than: 1.megabyte },
    file_content_type: { allow: ['image/jpeg', 'image/png'] }


  validates :name, presence: true
  validates :description, length: {in: 4..160}, allow_blank: true

  collection :users,
      prepopulator:      :prepopulate_users!,
      populate_if_empty: :populate_users!,
      skip_if:           :all_blank do

    property :email
    property :remove, virtual: true

    validates :email, presence: true, email: true
    validate :authorship_limit_reached?

    def readonly? # per form.
      model.persisted?
    end
    alias_method :removeable?, :readonly?

  private
    def authorship_limit_reached?
      return if model.authorships.find_all { |au| au.confirmed == 0 }.size < 5
      errors.add("user", "This user has too many unconfirmed authorships.")
    end
  end
  validates :users, length: {maximum: 3}
  validate :unconfirmed_users_limit_reached?

  def unconfirmed_users_limit_reached?
    users.each do |user|
      next unless users.added.include?(user) # this covers Update, and i don't really like it here.
      next if Thing::Create::IsLimitReached.(user.model, errors)
    end
  end

private
  def prepopulate_users!(options)
    (3 - users.size).times { users << User.new }
  end

  def populate_users!(params, options)
    User.find_by_email(params["email"]) or User.new
  end
end