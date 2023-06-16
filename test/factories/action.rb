FactoryBot.define do
  factory :action do
    type       {:airport_added}
    actionable factory: :airport
    user       factory: :known
  end
end
