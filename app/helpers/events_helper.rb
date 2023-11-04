module EventsHelper
  def week_of_month_default_option(event)
    return "day_#{event.recurring_day_of_month}" if event.recurring_day_of_month

    return "week_#{event.recurring_week_of_month}" if event.recurring_week_of_month

    return nil
  end
end
