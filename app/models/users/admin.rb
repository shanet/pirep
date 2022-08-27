class Users::Admin < Users::User
  def self.model_name
    return Users::User.model_name
  end
end
