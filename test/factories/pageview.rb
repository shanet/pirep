FactoryBot.define do
  factory :pageview do
    browser          {'Firefox'}
    browser_version  {'113'}
    ip_address       {'127.0.0.1'}
    latitude         {47.9073174}
    longitude        {-122.282094}
    operating_system {'Linux'}
    record           {create(:airport)}
    user             {create(:known)}
    user_agent       {'Mozilla/5.0 (X11; Linux x86_64; rv:113.0) Gecko/20100101 Firefox/113.0'}
  end
end
