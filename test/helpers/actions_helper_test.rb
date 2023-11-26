require 'test_helper'

class ActionsHelperTest < ActionView::TestCase
  include ActionsHelper

  test 'handles airport versions with no changes' do
    with_versioning do
      airport = create(:airport)
      airport.update!({})
      action = create(:action, type: :airport_edited, actionable: airport, version: airport.versions.last)

      assert_nil action_link(action), 'Did not return nil for airport version with no changes'
    end
  end

  test 'handles action with deleted airport' do
    with_versioning do
      airport = create(:airport)
      added_action = create(:action, type: :airport_added, actionable: airport, version: airport.versions.last)

      airport.update!({description: 'edited'})
      edited_action = create(:action, type: :airport_edited, actionable: airport, version: airport.versions.last)

      airport.destroy!

      [added_action, edited_action].each do |action|
        assert action_link(action.reload)[:label].include?(ActionsHelper::DELETED), 'Did not render deleted string for deleted airport actionable'
      end
    end
  end

  test 'handles action with deleted tag' do
    with_versioning do
      tag = create(:tag)
      added_action = create(:action, type: :tag_added, actionable: tag, version: tag.versions.last)

      tag.destroy!
      tag.airport.destroy!
      deleted_action = create(:action, type: :tag_removed, actionable: tag, version: tag.versions.last)

      [added_action, deleted_action].each do |action|
        assert action_link(action.reload)[:label].include?(ActionsHelper::DELETED), 'Did not render deleted string for deleted tag actionable'
      end
    end
  end

  test 'handles tag action without version' do
    with_versioning do
      tag = create(:tag)
      action = create(:action, type: :tag_added, actionable: tag)
      tag.destroy!

      # Not having a version to fallback on for a tag label should print the deleted text
      assert action_link(action.reload)[:label].include?(ActionsHelper::DELETED), 'Did not render deleted string for deleted tag actionable without version'
    end
  end

  test 'handles action with deleted webcam' do
    with_versioning do
      webcam = create(:webcam)
      action = create(:action, type: :webcam_added, actionable: webcam, version: webcam.versions.last)
      webcam.destroy!

      # This test is only deleting the webcam. The airport record remains so there should be no "deleted" text in the output
      assert_not action_link(action.reload)[:label].include?(ActionsHelper::DELETED), 'Rendered deleted string for deleted webcam actionable'
    end
  end

  test 'has airport for comment action' do
    with_versioning do
      comment = create(:comment)
      action = create(:action, type: :comment_added, actionable: comment)

      assert_not action_link(action.reload)[:label].include?(ActionsHelper::DELETED), 'Did not render action link for comment'
    end
  end
end
