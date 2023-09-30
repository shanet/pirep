class Webcam < ApplicationRecord
  IMAGE_LINK_EXTENSIONS = Set.new(['jpg', 'png', 'cgi', 'mjpg'])

  belongs_to :airport

  has_many :actions, as: :actionable, dependent: :nullify

  has_paper_trail meta: {airport_id: :airport_id}

  after_create :create_tag
  after_destroy :remove_tag

  # This is essentially a sanity check against invalid URLs. It's not intended to catch every possible invalid URL.
  validates :url, presence: true, length: {maximum: 1_000}, format: /\Ahttps?:\/\/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\/?.*\z/
  validates :url, uniqueness: {scope: :airport_id}

  def image?
    uri = URI.parse(url)

    # Don't consider http:// links to be direct image links as that would cause mixed content loading on our HTTPS website
    return uri.is_a?(URI::HTTPS) && File.extname(uri.path)[1..]&.in?(IMAGE_LINK_EXTENSIONS)
  end

  def url=(url)
    url = "https://#{url}" unless url.start_with?('https://', 'http://')
    super(url)
  end

private

  def create_tag
    # Create a tag for the airport when a webcam is created
    return if airport.tags.find_by(name: :webcam)

    airport.tags << Tag.new(name: :webcam)
  end

  def remove_tag
    # Remove a tag for the airport when a webcam is deleted and it was the last one
    return if airport.webcams.any?

    airport.tags.where(name: :webcam).destroy_all
  end
end
