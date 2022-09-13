FactoryBot.define do
  factory :user, class: Users::User do
    sequence(:name) {|i| "Foo Bar #{i}"}
    email           {"#{(name || 'foo').downcase.gsub(' ', '_')}@example.com"}
    password        {'R_2?pg"Qi`3;J~v+>(qHz#*Fm'}
    confirmed_at    {Time.zone.now}

    factory :admin, class: Users::Admin
    factory :known, class: Users::Known
    factory :unknown, class: Users::Unknown
  end
end
