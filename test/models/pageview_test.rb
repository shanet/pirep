require 'test_helper'

class PageviewTest < ActiveSupport::TestCase
  USER_AGENTS = {
    firefox: {
      user_agent: 'Mozilla/5.0 (X11; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/111.0.1',
      browser: 'Firefox',
      browser_version: '111',
      operating_system: 'Linux',
      is_spider: false,
    },
    chrome: {
      user_agent: 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.2526.111 Safari/537.36',
      browser: 'Chrome',
      browser_version: '111',
      operating_system: 'Windows',
      is_spider: false,
    },
    safari: {
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9',
      browser: 'Safari',
      browser_version: '9',
      operating_system: 'Mac OS X',
      is_spider: false,
    },
    edge: {
      user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246',
      browser: 'Edge',
      browser_version: '12',
      operating_system: 'Windows',
      is_spider: false,
    },
    android: {
      user_agent: 'Mozilla/5.0 (Linux; Android 13; SM-A205U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.5672.76 Mobile Safari/537.36',
      browser: 'Chrome Mobile',
      browser_version: '113',
      operating_system: 'Android',
      is_spider: false,
    },
    ios: {
      user_agent: 'Mozilla/5.0 (iPhone14,3; U; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/19A346 Safari/602.1',
      browser: 'Mobile Safari',
      browser_version: '10',
      operating_system: 'iOS',
      is_spider: false,
    },
    googlebot: {
      user_agent: 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
      browser: 'Googlebot',
      browser_version: '2',
      operating_system: 'Other',
      is_spider: true,
    },
    empty: {
      user_agent: '',
      browser: 'Other',
      browser_version: nil,
      operating_system: 'Other',
      is_spider: true,
    },
    nil: {
      user_agent: nil,
      browser: 'Other',
      browser_version: nil,
      operating_system: 'Other',
      is_spider: true,
    },
  }

  test 'spider?' do
    USER_AGENTS.each do |key, user_agent|
      assert_equal user_agent[:is_spider], Pageview.spider?(user_agent[:user_agent]), "Incorrectly parsed spider for #{key}"
    end
  end

  test 'parses user agent' do
    USER_AGENTS.each do |key, user_agent|
      pageview = Pageview.new(user_agent: user_agent[:user_agent])
      assert_equal user_agent[:browser], pageview.browser, "User agent browser parsed incorrectly for #{key}"
      assert_equal user_agent[:operating_system], pageview.operating_system, "User agent operating system parsed incorrectly for #{key}"

      # Annoyingly, this has to use different methods to avoid a deprecation warning
      if user_agent[:browser_version].nil?
        assert_nil pageview.browser_version, "User agent browser version parsed incorrectly for #{key}"
      else
        assert_equal user_agent[:browser_version], pageview.browser_version, "User agent browser version parsed incorrectly for #{key}"
      end
    end
  end

  test 'parses IP address' do
    pageview = Pageview.new(ip_address: '8.8.8.8')
    assert_not_nil pageview.latitude, 'Did not parse IP location'
    assert_not_nil pageview.longitude, 'Did not parse IP location'
  end
end
