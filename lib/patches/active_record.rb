class ActiveRecord::Base
  def self.page(page_number, per_page=Rails.configuration.pagination_page_size)
    page_number ||= 0
    return limit(per_page).offset(page_number.to_i * per_page)
  end
end
