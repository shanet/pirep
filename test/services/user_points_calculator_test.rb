require 'test_helper'

class UserPointsCalculatorTest < ActiveSupport::TestCase
  test 'calulates points for user' do
    user = create(:known)

    # Users should start with zero points
    assert_equal 0, UserPointsCalculator.new(user).points, 'Wrong points calculated for user'

    create_list(:action, 3, type: :airport_edited, user: user)
    create(:action, type: :airport_added, user: user)
    create(:action, type: :comment_flagged, user: user)
    create(:action, type: :comment_added, user: user)

    assert_equal 850, UserPointsCalculator.new(user).points, 'Wrong points calculated for user'
  end

  test 'ranks user' do
    user = create(:known, points: 100)
    create(:admin, points: 200)
    create(:known, points: 0)
    create(:unknown, points: 50)

    assert_equal 2, UserPointsCalculator.new(user).rank, 'Wrong rank for user'
  end

  test 'returns points for an action' do
    assert_equal UserPointsCalculator::POINT_VALUES[:airport_added], UserPointsCalculator.points_for_action(:airport_added), 'Mismatching points value'
    assert_nil UserPointsCalculator.points_for_action(:tag_removed), 'Mismatching points value'
  end
end
