class Event < ApplicationRecord
  include UrlValidator

  belongs_to :airport
  has_many :actions, as: :actionable, dependent: :nullify

  has_paper_trail meta: {airport_id: :airport_id}

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :end_date, comparison: {greater_than: :start_date}
  validates :digest, uniqueness: {scope: :airport_id}, allow_blank: true

  validates :recurring_cadence, presence: true, if: :recurring?
  validates :recurring_interval, presence: true, if: :recurring?

  validates :recurring_interval, numericality: {only_integer: true}, allow_nil: true
  validates :recurring_day_of_month, numericality: {only_integer: true}, allow_nil: true
  validates :recurring_week_of_month, numericality: {only_integer: true}, allow_nil: true

  validate :recurring_monthly_presence
  validate :recurring_day_week_of_month_xor

  after_create :create_tag
  after_destroy :remove_tag

  RECURRING_CADENCE = {
    daily: 'Day',
    weekly: 'Week',
    monthly: 'Month',
    yearly: 'Year',
  }

  enum recurring_cadence: RECURRING_CADENCE.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}
  enum data_source: {aopa: 'aopa', eaa: 'eaa', user_contributed: 'user_contributed'}

  # All single events in the future and all recurring events
  scope :upcoming, -> {where('start_date > ?', Time.zone.now).or(where.not(recurring_cadence: nil))}

  def recurring?
    return recurring_cadence.present?
  end

  def recurring_cadence
    return self[:recurring_cadence]&.to_sym
  end

  def recurring_week_of_month_label
    return nil unless recurring_week_of_month

    return 'last' if recurring_week_of_month == -1

    return ['first', 'second', 'third', 'fourth', 'fifth'][recurring_week_of_month - 1]
  end

  def next_start_date
    return start_date unless recurring?

    next_start_date = recurrance_schedule(start_date).next_occurrence

    # Annoying edge case: If the event start date is during DST and the next recurring date is not then we need to adjust by an hour to keep the times consistent
    if start_date.in_time_zone(airport.timezone).dst? && !next_start_date.in_time_zone(airport.timezone).dst?
      next_start_date += 1.hour
    elsif !start_date.in_time_zone(airport.timezone).dst? && next_start_date.in_time_zone(airport.timezone).dst?
      next_start_date -= 1.hour
    end

    return next_start_date
  end

  def next_end_date
    return end_date unless recurring?

    # For a recurring event the end date is the next start date + the difference between the start and end dates.
    # Otherwise there is an edge case for a multi-day event when the start date has passed but not the end date.
    return next_start_date + (end_date - start_date)
  end

  def url=(url)
    url = "https://#{url}" if url.present? && !url.start_with?('https://', 'http://')
    super(url)
  end

private

  def recurrance_schedule(date)
    return IceCube::Schedule.new(date) do |schedule|
      case recurring_cadence
        when :daily
          schedule.add_recurrence_rule(IceCube::Rule.daily(recurring_interval))
        when :weekly
          schedule.add_recurrence_rule(IceCube::Rule.weekly(recurring_interval))
        when :monthly, :yearly
          if recurring_day_of_month.present?
            schedule.add_recurrence_rule(IceCube::Rule.send(recurring_cadence, recurring_interval).day_of_month(recurring_day_of_month))
          elsif recurring_week_of_month.present?
            schedule.add_recurrence_rule(IceCube::Rule.send(recurring_cadence, recurring_interval).day_of_week({start_date.wday => [recurring_week_of_month]}))
          end
      end
    end
  end

  def recurring_monthly_presence
    # Ensure that a recurring day/week of month is selected for monthly/yearly recurring events
    if recurring? && [:monthly, :yearly].include?(recurring_cadence) && recurring_day_of_month.blank? && recurring_week_of_month.blank? # rubocop:disable Style/GuardClause
      errors.add(:base, 'A time period for a monthly recurring event must be selected.')
    end
  end

  def recurring_day_week_of_month_xor
    if recurring_day_of_month && recurring_week_of_month # rubocop:disable Style/GuardClause
      errors.add(:base, 'Both recurring day-of-month and week-of-month cannot be specified.')
    end
  end

  def create_tag
    # Create a tag for the airport when an event is created
    return if airport.tags.find_by(name: :events)

    airport.tags << Tag.new(name: :events)
  end

  def remove_tag
    # Remove a tag for the airport when an event is deleted and it was the last one
    return if airport.events.any?

    airport.tags.where(name: :events).destroy_all

    # Schedule an airport cache refresh so the event's airport is no longer shown under the events tag
    AirportGeojsonDumperJob.perform_later
  end
end
