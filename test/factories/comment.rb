FactoryBot.define do
  factory :comment do
    body {'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'}
    airport

    trait :helpful do
      helpful_count {42}
    end

    trait :outdated do
      outdated_at {Time.zone.now}
    end
  end
end
