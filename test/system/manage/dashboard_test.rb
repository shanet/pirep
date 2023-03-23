require 'application_system_test_case'

class Manage::DashboardTest < ApplicationSystemTestCase
  setup do
    @comment = create(:comment)
  end

  test 'marks item in queue as reviewed' do
    sign_in :admin
    visit manage_root_path

    # Apporving a record from the review queue should remove it from the queue
    find(".review-record[data-record-id=\"#{@comment.id}\"] form button").click
    assert_no_selector ".review-record[data-record-id=\"#{@comment.id}\"]"
  end
end
