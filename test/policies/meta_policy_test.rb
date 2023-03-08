require 'policy_test'

class MetaPolicyTest < PolicyTest
  [:health, :sitemap].each do |route|
    test route do
      assert_allows_all :meta, route
    end
  end
end
