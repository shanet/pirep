require 'test_helper'

class MetaControllerTest < ActionDispatch::IntegrationTest
  test 'healthcheck' do
    assert_difference('Users::Unknown.count', 0) do
      get health_path
      assert_response :success
    end
  end

  test 'sitemap' do
    airport = create(:airport)
    get sitemap_path

    assert_response :success
    assert airport.code.in?(response.body), 'Airport not included in sitemap'
  end

  # Not being logged in should redirect to the log in page for the GoodJob dashboard
  # There's no controller under app/ for this so this test is stuck in the meta controller test class
  test 'GoodJob dashboard' do
    get GoodJob::Engine.routes.url_helpers.root_path
    assert_response :redirect
  end
end
