FactoryBot.define do
  factory :tag do
    name {Tag::TAGS.keys.first}
    airport
  end
end
