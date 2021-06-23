FactoryBot.define do
  factory :remark do
    sequence(:element) {|count| 'WAE11%d' % count}
    text {'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'}
    airport
  end
end
