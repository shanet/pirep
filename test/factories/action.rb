FactoryBot.define do
  factory :action do
    type {:airport_added}
    actionable {create(:airport)}
    user {create(:known)}
  end
end
