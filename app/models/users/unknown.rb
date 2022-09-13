class Users::Unknown < Users::User
  @randomize_credentials = proc do |user|
    # Users must have email addresses and password so provide some dummy values for unknown users
    user.email = "#{SecureRandom.uuid}@pirep.io"
    user.password = SecureRandom.uuid
  end

  def self.model_name
    return Users::User.model_name
  end

  def self.create_or_find_by(**kwargs)
    return super(kwargs, &@randomize_credentials)
  end

  def self.create_or_find_by!(**kwargs)
    return super(kwargs, &@randomize_credentials)
  end

  # These users may not log in
  def active_for_authentication?
    return false
  end
end
