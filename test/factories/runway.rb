FactoryBot.define do
  factory :runway do
    number {'16R/34L'}
    length {9010}
    surface {'ASPH-CONC-G'}
    lights {'HIGH'}
    airport
  end
end
