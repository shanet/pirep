FactoryBot.define do
  factory :action do
    type {:airport_edited}
    actionable {create(:airport)}
    user {create(:known)}
  end
end
