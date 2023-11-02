FactoryBot.define do
  factory :event do
    name       {'AirVenture'}
    start_date {DateTime.new(2023, 7, 24, 8)}
    end_date   {DateTime.new(2023, 7, 30, 17)}
    host       {'EAA'}
    location   {'Oshkosh'}
    url        {'https://example.com'}
    airport

    trait :recurring do
      recurring_interval      {1}
      recurring_cadence       {:yearly}
      recurring_week_of_month {4}
    end
  end
end
