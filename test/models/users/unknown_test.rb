require 'test_helper'

class Users::UnknownTest < ActiveSupport::TestCase
  test 'create or find by' do
    assert_difference('Users::Unknown.count', 2) do
      # This class overrides both the bang and non-bang methods so call both to test each and also ensure
      # that calling twice create two users instead of creating one and simply finding the second one
      Users::Unknown.create_or_find_by(ip_address: '127.0.0.1') # rubocop:disable Rails/SaveBang
      Users::Unknown.create_or_find_by!(ip_address: '127.0.0.2')
    end
  end

  test 'can not log in' do
    assert_not create(:unknown).active_for_authentication?, 'Unknown user may log in'
  end
end
