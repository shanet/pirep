class Action < ApplicationRecord
  belongs_to :user, class_name: Users::User.name.to_s
  belongs_to :actionable, polymorphic: true
  belongs_to :version, class_name: PaperTrail::Version.name.to_s, optional: true

  self.inheritance_column = nil

  ACTIONS = [
    :airport_added,
    :airport_edited,
    :airport_photo_uploaded,

    :comment_added,
    :comment_flagged,
    :comment_helpful,
    :comment_unflagged,

    :event_added,
    :event_edited,
    :event_removed,

    :tag_added,
    :tag_removed,

    :webcam_added,
  ].to_set

  validates :type, inclusion: {in: ACTIONS.map(&:to_s)}

  # Actions that denote an "edit" (basically, not including comment actions as these aren't really contributions to airports)
  def self.edited_actions
    return [
      :airport_edited,
      :airport_added,
      :event_added,
      :event_edited,
      :event_removed,
      :tag_added,
      :tag_removed,
      :webcam_added,
    ]
  end

  # Get the given attribute from the version associated with the action for deleted actionable records
  def historical_value(attribute)
    return nil unless version

    return version.object&.[](attribute.to_s) || version.object_changes&.[](attribute.to_s)&.compact&.first
  end
end
