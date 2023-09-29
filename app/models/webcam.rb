class Webcam < ApplicationRecord
  IMAGE_LINK_EXTENSIONS = Set.new(['jpg', 'png', 'cgi'])

  belongs_to :airport

  has_many :actions, as: :actionable, dependent: :destroy

  has_paper_trail meta: {airport_id: :airport_id}

  # This is essentially a sanity check against invalid URLs. It's not intended to catch every possible invalid URL.
  validates :url, presence: true, length: {maximum: 1_000}, format: /\Ahttps?:\/\/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\/?.*\z/

  def image?
    uri = URI.parse(url)

    # Don't consider http:// links to be direct image links as that would cause mixed content loading on our HTTPS website
    return uri.is_a?(URI::HTTPS) && File.extname(uri.path)[1..]&.in?(IMAGE_LINK_EXTENSIONS)
  end

  def url=(url)
    url = "https://#{url}" unless url.start_with?('https://', 'http://')
    super(url)
  end
end
