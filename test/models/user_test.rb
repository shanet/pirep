require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'first name' do
    user1 = create(:known, name: 'Foo Bar')
    assert_equal 'Foo', user1.first_name

    user2 = create(:known, name: nil)
    assert_nil user2.first_name, 'Did not handle nil name'
  end
end
