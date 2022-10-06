class Comment < ApplicationRecord
  belongs_to :airport
  belongs_to :user, class_name: Users::User.name.to_s

  has_many :actions, as: :actionable, dependent: :destroy

  validates :helpful_count, numericality: {}
  validates :body, presence: true

  def found_helpful?(user)
    return actions.find_by(user: user, type: :comment_helpful)
  end
end
