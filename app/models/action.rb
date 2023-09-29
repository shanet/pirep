class Action < ApplicationRecord
  belongs_to :user, class_name: Users::User.name.to_s
  belongs_to :actionable, polymorphic: true
  belongs_to :version, class_name: PaperTrail::Version.name.to_s, optional: true

  self.inheritance_column = nil

  ACTIONS = [
    :airport_edited,
    :airport_added,
    :airport_photo_uploaded,

    :tag_added,
    :tag_removed,

    :comment_added,
    :comment_helpful,
    :comment_flagged,
    :comment_unflagged,

    :webcam_added,
  ].to_set

  validates :type, inclusion: {in: ACTIONS.map(&:to_s)}

  # Actions that denote an "edit" (basically, not including comment actions as these aren't really contributions to airports)
  def self.edited_actions
    return [
      :airport_edited,
      :airport_added,
      :tag_added,
      :tag_removed,
      :webcam_added,
    ]
  end
end
