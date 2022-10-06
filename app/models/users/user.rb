class Users::User < ApplicationRecord
  include Searchable

  devise :confirmable, :database_authenticatable, :lockable, :recoverable, :registerable, :rememberable, :trackable, :validatable

  has_many :comments, dependent: :destroy
  has_many :actions, dependent: :destroy

  # Only allow unknown users to have IP addresses to avoid conflicts with known users that are identified by their email addresses
  validates :ip_address, presence: true, if: :unknown?
  validates :ip_address, absence: true, unless: :unknown?

  searchable({column: :email, weight: :A})
  searchable({column: :name, weight: :B})
  searchable({column: :ip_address})
  searchable({column: :last_sign_in_ip})

  def first_name
    return name&.split(' ')&.first
  end

  def admin?
    return type == Users::Admin.name
  end

  def known?
    return type == Users::Known.name
  end

  def unknown?
    return type == Users::Unknown.name
  end
end
