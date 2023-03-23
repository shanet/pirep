require 'application_system_test_case'

class Manage::UsersTest < ApplicationSystemTestCase
  setup do
    @user = create(:known)
  end

  test 'sets timestamp on user edit form' do
    sign_in :admin
    visit edit_manage_user_path(@user)

    find('#users_user_locked_at + a').click

    # The Ruby and JavaScript ISO8601 formats are slightly different with milliseconds so just do a starts with check here and drop the timezone ("Z")
    assert find_field('users_user_locked_at', with: /.+Z$/).value.start_with?(Time.zone.now.iso8601.gsub('Z', ''))
  end
end
