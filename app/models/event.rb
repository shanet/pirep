class Event < ApplicationRecord
  include UrlValidator

  belongs_to :airport
  has_many :actions, as: :actionable, dependent: :nullify

  has_paper_trail meta: {airport_id: :airport_id}

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :end_date, comparison: {greater_than: :start_date}
  validates :recurring_cadence, presence: true, if: :recurring?
  validates :recurring_interval, presence: true, if: :recurring?
  validate :recurring_monthly_presence

  after_create :create_tag
  after_destroy :remove_tag

  RECURRING_CADENCE = {
    daily: 'Day',
    weekly: 'Week',
    monthly: 'Month',
    yearly: 'Year',
  }

  enum recurring_cadence: RECURRING_CADENCE.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

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

    return ['first', 'second', 'third', 'last'][recurring_week_of_month - 1]
  end

  def next_start_date
    return (recurring? ? recurrance_schedule(start_date).next_occurrence : start_date)
  end

  def next_end_date
    return end_date unless recurring?

    # For a recurring event the end date is the next start date + the difference between the start and end dates.
    # Otherwise there is an edge case for a multi-day event when the start date has passed but not the end date.
    return recurrance_schedule(start_date).next_occurrence + (end_date - start_date)
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

  def create_tag
    # Create a tag for the airport when an event is created
    return if airport.tags.find_by(name: :events)

    airport.tags << Tag.new(name: :events)
  end

  def remove_tag
    # Remove a tag for the airport when an event is deleted and it was the last one
    return if airport.events.any?

    airport.tags.where(name: :events).destroy_all
  end
end