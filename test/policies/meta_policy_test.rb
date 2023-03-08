require 'policy_test'

class MetaPolicyTest < PolicyTest
  [:health, :sitemap] do |route|
    test route do
      assert_allows_all :meta, route
    end
  end
end
