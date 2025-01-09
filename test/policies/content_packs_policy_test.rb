require 'policy_test'

class ContentPacksPolicyTest < PolicyTest
  test 'index' do
    assert_allows_all :content_packs, :index
  end

  test 'show' do
    assert_allows_all :content_packs, :show
  end
end
