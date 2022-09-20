require 'test_helper'

class Users::UserTest < ActiveSupport::TestCase
  test 'first name' do
    user1 = create(:known, name: 'Foo Bar')
    assert_equal 'Foo', user1.first_name

    user2 = create(:known, name: nil)
    assert_nil user2.first_name, 'Did not handle nil name'
  end

  test 'is admin?' do
    assert create(:admin).admin?
    assert_not create(:known).admin?
    assert_not create(:unknown).admin?
  end

  test 'is known?' do
    assert_not create(:admin).known?
    assert create(:known).known?
    assert_not create(:unknown).known?
  end

  test 'is unknown?' do
    assert_not create(:admin).unknown?
    assert_not create(:known).unknown?
    assert create(:unknown).unknown?
  end
end
