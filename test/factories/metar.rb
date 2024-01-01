FactoryBot.define do
  factory :metar do
    airport factory: :airport

    cloud_layers    {[{altitude: 3000, coverage: 'FEW'}, {altitude: 5000, coverage: 'OVC'}]}
    dewpoint        {0}
    flight_category {'VFR'}
    observed_at     {Time.zone.now}
    temperature     {10}
    visibility      {10}
    weather         {'-RA'}
    wind_direction  {180}
    wind_speed      {15}

    # No, this doesn't match the values above
    raw {'KPAE 010053Z 18015KT 10SM CLR 07/04 A3019 RMK AO2 SLP226 T00720039'}
  end
end
