class Users::Unknown < Users::User
  def self.model_name
    return Users::User.model_name
  end

  def self.create_or_find_by(**kwargs)
    return super(kwargs) {|user| randomize_credentials(user)}
  end

  def self.create_or_find_by!(**kwargs)
    return super(kwargs) {|user| randomize_credentials(user)}
  end

  # These users may not log in
  def active_for_authentication?
    return false
  end

  # Don't send a confirmation email to unknown users since we don't know their email address
  def send_confirmation_notification?
    return false
  end

  private_class_method def self.randomize_credentials(user)
    # Users must have email addresses and password so provide some dummy values for unknown users
    user.email = "#{SecureRandom.uuid}@pirep.io"
    user.password = SecureRandom.uuid
  end
end
