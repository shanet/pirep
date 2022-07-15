FactoryBot.define do
  factory :airport do
    name {'SNOHOMISH COUNTY (PAINE FLD)'}
    sequence(:code) {|count| 'PAE%d' % count}
    latitude {47.9073174}
    longitude {-122.282094}
    sequence(:site_number) {|count| '2621%d.*A' % count}
    facility_type {'airport'}
    facility_use {'PU'}
    ownership_type {'PU'}
    owner_name {'SNOHOMISH COUNTY'}
    owner_phone {'425-388-3411'}
    description {'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'}
    transient_parking {'Nunc aliquet porttitor porttitor.'}
    fuel_location {'Quisque malesuada quam nec ultricies placerat.'}
    crew_car {'Integer lacinia elementum sapien, in fermentum nibh pretium et.'}
    landing_fees {'Proin eget dignissim nunc.'}
    wifi {'Integer convallis tincidunt mi, quis pulvinar nulla bibendum nec.'}
    elevation {607}
    fuel_type {'100LLA'}
    gate_code {'123.0'}
    landing_rights {:public_}
    photos {[Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png')]}

    after(:create) do |airport, _evaluator|
      create(:runway, airport: airport)
      create(:remark, airport: airport)
    end

    trait :empty do
      crew_car {nil}
      description {nil}
      fuel_location {nil}
      landing_fees {nil}
      transient_parking {nil}
      wifi {nil}

      after(:create) do |airport, _evaluator|
        create(:tag, name: :empty, airport: airport)
      end
    end
  end
end
