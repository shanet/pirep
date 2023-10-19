FactoryBot.define do
  factory :webcam do
    sequence(:url) {|count| "https://example.com/webcam#{count}.jpg"}
    airport

    trait :frame do
      url {Rails.configuration.content_security_policy_whitelisted_frame_domains.first}
    end
  end
end
