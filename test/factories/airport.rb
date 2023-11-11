FactoryBot.define do
  factory :airport do
    name                 {'SNOHOMISH COUNTY (PAINE FLD)'}
    sequence(:code)      {|count| "PAE#{count}"}
    sequence(:icao_code) {|count| "KPAE#{count}"}
    latitude             {47.9073174}
    longitude            {-122.282094}
    coordinates          {[latitude, longitude]}
    city                 {'EVERETT'}
    state                {'WA'}
    country              {'us'}
    elevation            {607}
    facility_type        {'airport'}
    facility_use         {'PU'}
    ownership_type       {'PU'}
    description          {'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'}
    transient_parking    {'Nunc aliquet porttitor porttitor.'}
    fuel_location        {'Quisque malesuada quam nec ultricies placerat.'}
    crew_car             {'Integer lacinia elementum sapien, in fermentum nibh pretium et.'}
    landing_fees         {'Proin eget dignissim nunc.'}
    wifi                 {'Integer convallis tincidunt mi, quis pulvinar nulla bibendum nec.'}
    fuel_types           {['100LL', 'UL100']}
    landing_rights       {:public_}
    sectional            {'seattle'}
    diagram              {'diagram.png'}
    data_source          {'faa'}
    bbox_checked         {true}
    bbox_ne_latitude     {47.922902}
    bbox_ne_longitude    {-122.2691531}
    bbox_sw_latitude     {47.8966986}
    bbox_sw_longitude    {-122.2918449}
    timezone             {'America/Los_Angeles'}
    timezone_checked_at  {Time.zone.now}
    contributed_photos   {[Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png')]}

    annotations do
      [
        {label: 'Gas Pumps', latitude: 47.90486159816672, longitude: -122.27569781859118},
        {label: 'Maintenance', latitude: 47.90477730148692, longitude: -122.27044785690572},
      ]
    end

    after(:create) do |airport, _evaluator|
      create(:runway, airport: airport)
      create(:remark, airport: airport)
    end

    trait :empty do
      crew_car          {nil}
      description       {nil}
      fuel_location     {nil}
      landing_fees      {nil}
      transient_parking {nil}
      wifi              {nil}
      annotations       {nil}

      after(:create) do |airport, _evaluator|
        create(:tag, name: :empty, airport: airport)
      end
    end

    trait :closed do
      after(:create) do |airport, _evaluator|
        create(:tag, name: :closed, airport: airport)
      end
    end

    trait :no_bounding_box do
      bbox_ne_latitude  {nil}
      bbox_ne_longitude {nil}
      bbox_sw_latitude  {nil}
      bbox_sw_longitude {nil}
    end

    trait :unmapped do
      # Override the attributes above to more closely match what data an unmapped airport will be created with
      city                 {nil}
      state                {nil}
      fuel_types           {nil}
      sectional            {nil}
      diagram              {nil}
      bbox_ne_latitude     {nil}
      bbox_ne_longitude    {nil}
      bbox_sw_latitude     {nil}
      bbox_sw_longitude    {nil}

      after(:create) do |airport, _evaluator|
        create(:tag, name: :unmapped, airport: airport)
      end
    end
  end
end
