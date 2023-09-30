FactoryBot.define do
  factory :webcam do
    sequence(:url) {|count| "https://example.com/webcam#{count}.jpg"}
    airport
  end
end
