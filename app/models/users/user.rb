class Users::User < ApplicationRecord
  devise :confirmable, :database_authenticatable, :lockable, :recoverable, :registerable, :rememberable, :trackable, :validatable

  def first_name
    return name&.split(' ')&.first
  end
end
