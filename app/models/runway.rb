class Runway < ApplicationRecord
  belongs_to :airport

  def length_threat_level
    case length
      when -Float::INFINITY..1999
        return 'red'
      when 2000..2999
        return 'orange'
      when 3000..Float::INFINITY
        return 'green'
      else
        return 'green'
    end
  end
end
