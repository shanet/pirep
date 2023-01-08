require 'policy_test'

class AirportPolicyTest < PolicyTest
  setup do
    @airport = create(:airport)
  end

  ['index', 'show', 'search', 'history', 'preview', 'annotations'].each do |action|
    test action do
      assert_allows_all @airport, action
    end
  end

  test 'new' do
    assert_allows_all @airport, :new, allow_disabled: false
  end

  ['create', 'update'].each do |action|
    test action do
      assert_allows_all @airport, action, allow_disabled: false

      Rails.configuration.read_only.enable!
      assert_denies_all @airport, action
    ensure
      Rails.configuration.read_only.disable!
    end
  end

  test 'update, locked airport' do
    @airport.update!(locked_at: Time.zone.now)
    assert_denies_all @airport, :update
  end

  test 'revert' do
    assert_allows_admin @airport, :revert
  end
end
