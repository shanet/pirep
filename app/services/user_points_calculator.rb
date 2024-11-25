class UserPointsCalculator
  POINT_VALUES = {
    airport_added: 500,
    airport_edited: 100,
    airport_photo_uploaded: 100,
    comment_added: 50,
    event_added: 50,
    tag_added: 100,
    webcam_added: 100,
  }

  def initialize(user)
    @user = user
  end

  def points
    points = 0

    @user.actions.find_each do |action|
      points += self.class.points_for_action(action.type) || 0
    end

    return points
  end

  def rank
    position_query = <<-SQL.squish
      SELECT position FROM (
        SELECT id, ROW_NUMBER() OVER (ORDER BY points DESC) AS position
        FROM #{@user.class.table_name}
        WHERE points > 0
      ) AS subquery
      WHERE id = '#{@user.id}';
    SQL

    return ApplicationRecord.connection.execute(position_query).first&.[]('position')
  end

  def self.points_for_action(action_type)
    return POINT_VALUES[action_type.to_sym]
  end
end
