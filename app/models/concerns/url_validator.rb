module UrlValidator
  extend ActiveSupport::Concern

  included do
    # This is essentially a sanity check against invalid URLs. It's not intended to catch every possible invalid URL.
    validates :url, length: {maximum: 255}, format: /\Ahttps?:\/\/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\/?.*\z/, allow_blank: true
  end
end
