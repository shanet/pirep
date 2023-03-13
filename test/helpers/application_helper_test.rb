require 'test_helper'

class ApplicationTest < ActionView::TestCase
  include ApplicationHelper

  test 'format timestamp handles nil values' do
    assert_nil format_timestamp(nil)
  end

  test 'format timestamps handles user\'s timezone' do
    assert_equal 'UTC', format_timestamp(Time.zone.now, format: '%Z'), 'Timestamp did not default to UTC'
    @current_user = create(:known, timezone: 'America/New_York')

    timezone = (Time.now(in: TZInfo::Timezone.get('America/New_York')).dst? ? 'EDT' : 'EST')
    assert_equal timezone, format_timestamp(Time.zone.now, format: '%Z'), 'Timestamp not in user\'s timezone'
  end

  test 'does not allow XSS in markdown' do
    markdown = render_markdown('<script>alert("uh oh!")</script>')
    assert_not markdown.include?('script'), 'Markdown rendering let script tags through'
  end

  test 'user label' do
    unknown = create(:unknown)
    known = create(:known)

    assert_equal unknown.ip_address, user_label(unknown)
    assert_equal known.email, user_label(known)
  end

  test 'FAA data content URL' do
    filename = 'diagram.png'
    assert_equal "/assets/diagrams/current/#{filename}", faa_data_content_url(:diagrams, filename: filename), 'Unexpected diagrams URL without CDN'

    Rails.configuration.action_controller.asset_host = 'https://cdn.example.com'
    Rails.configuration.tiles_host = 'https://tiles.example.com'
    Rails.configuration.cdn_content_path = 'content'

    assert_equal "https://cdn.example.com/content/diagrams/current/#{filename}", faa_data_content_url(:diagrams, filename: filename), 'Unexpected diagrams URL with CDN'
    assert_equal 'https://tiles.example.com/content/terminal/current/', faa_data_content_url(:charts, path: :terminal), 'Unexpected charts URL with CDN'
  ensure
    Rails.configuration.action_controller.asset_host = nil
    Rails.configuration.tiles_host = nil
    Rails.configuration.cdn_content_path = nil
  end

private

  def current_user
    return @current_user
  end
end
