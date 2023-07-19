namespace :pageviews do
  desc 'Generate summary of pageview records'
  task summary: :environment do
    period = 60 # Days

    grouped_pageviews = Pageview
      .joins(:user)
      .where('pageviews.created_at > ?', period.days.ago)
      .where.not(user: {type: Users::Admin.name})
      .group('pageviews.created_at::date')

    total_pageviews = grouped_pageviews.count
    unique_pageviews = grouped_pageviews.distinct.select(:user_id).count

    rows = total_pageviews.map do |date, total|
      [date, total, unique_pageviews[date]]
    end

    rows.sort_by! {|row| row[0]}

    summary_table = Terminal::Table.new do |table|
      table.title = "Pageview Summary\n(last #{period} days, non-admins)"
      table.headings = ['Date', 'Total', 'Unique']
      table.rows = rows
    end

    puts summary_table
  end
end
