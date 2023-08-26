require 'test_helper'

class ActionsHelperTest < ActionView::TestCase
  include ActionsHelper

  test 'handles airport versions with no changes' do
    with_versioning do
      airport = create(:airport)
      airport.update!({})
      action = create(:action, type: :airport_edited, version: airport.versions.last)

      assert_nil action_link(action), 'Did not return nil for airport version with no changes'
    end
  end
end
