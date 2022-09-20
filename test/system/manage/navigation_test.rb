require 'application_system_test_case'

class Manage::NavigationTest < ApplicationSystemTestCase
  test 'has breadcrumbs set' do
    airport = create :airport

    sign_in :admin
    visit edit_manage_airport_path(airport)

    assert_selector '.breadcrumb-item', count: 4
    assert_selector '.breadcrumb-item:first-child', text: 'Manage'
    assert_selector '.breadcrumb-item:nth-child(2)', text: 'Airports'
    assert_selector '.breadcrumb-item:nth-child(3)', text: airport.code
    assert_selector '.breadcrumb-item:last-child.active', text: 'Edit'
  end
end
