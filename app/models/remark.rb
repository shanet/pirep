class Remark < ApplicationRecord
  belongs_to :airport

  def to_human_readable
    return text.downcase.capitalize
  end
end
