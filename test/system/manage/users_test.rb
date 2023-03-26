require 'application_system_test_case'

class Manage::UsersTest < ApplicationSystemTestCase
  setup do
    @user = create(:known)
  end

  test 'sets timestamp on user edit form' do
    sign_in :admin
    visit edit_manage_user_path(@user)

    find('#users_user_locked_at + a').click

    timestamp = DateTime.parse(find_field('users_user_locked_at', with: /.+Z$/).value)
    assert_in_delta timestamp.to_i, Time.zone.now.to_i, 1.minute
  end
end
