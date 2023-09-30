require 'test_helper'

class ActionTest < ActiveSupport::TestCase
  test 'historical_value without version' do
    assert_nil create(:action).historical_value(:code), 'Historical value found for action without version'
  end

  test 'historical_value with version' do
    with_versioning do
      airport = create(:airport)
      action = create(:action, type: :airport_added, actionable: airport, version: airport.versions.last)
      airport.destroy!

      assert_equal airport.code, action.reload.historical_value(:code), 'Did not get attribute from action version'
    end
  end
end
