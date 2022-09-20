class Comment < ApplicationRecord
  belongs_to :airport
  belongs_to :user, class_name: Users::User.name.to_s

  validates :helpful_count, numericality: {}
  validates :body, presence: true
end
