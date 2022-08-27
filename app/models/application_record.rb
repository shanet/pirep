class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def short_id
    return id[0..7]
  end
end
