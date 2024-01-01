FactoryBot.define do
  factory :taf do
    airport factory: :airport

    cloud_layers    {[{altitude: 3000, coverage: 'FEW'}, {altitude: 5000, coverage: 'OVC'}]}
    ends_at         {1.hour.from_now}
    starts_at       {Time.zone.now}
    visibility      {6}
    wind_direction  {180}
    wind_speed      {15}

    # No, this doesn't match the values above
    raw {'KPAE 312324Z 0100/0124 00000KT P6SM FEW040 BKN200 FM010300 05003KT P6SM BKN250 FM010600 10002KT P6SM OVC015 FM011200 13003KT P6SM OVC004 FM011800 13005KT P6SM BKN250'}
  end
end
