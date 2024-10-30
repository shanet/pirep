class ActiveRecord::Base
  def self.page(page_number, per_page=Rails.configuration.pagination_page_size)
    page_number = page_number.to_i
    page_number = 0 if page_number < 0

    return limit(per_page).offset(page_number * per_page)
  end
end
