require 'test_helper'

class ApplicationTest < ActionView::TestCase
  include ApplicationHelper

  test 'format timestamp handles nil values' do
    assert_nil format_timestamp(nil)
  end

  test 'format timestamps handles user\'s timezone' do
    assert_equal 'UTC', format_timestamp(Time.zone.now, format: '%Z'), 'Timestamp did not default to UTC'

    @current_user = create(:known, timezone: 'America/New_York')
    assert_equal 'EST', format_timestamp(Time.zone.now, format: '%Z'), 'Timestamp not in user\'s timezone'
  end

  test 'does not allow XSS in markdown' do
    markdown = render_markdown('<script>alert("uh oh!")</script>')
    assert_not markdown.include?('script'), 'Markdown rendered let script tags through'
  end

  test 'user label' do
    unknown = create(:unknown)
    known = create(:known)

    assert_equal unknown.ip_address, user_label(unknown)
    assert_equal known.email, user_label(known)
  end

private

  def current_user
    return @current_user
  end
end
