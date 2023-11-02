class Webcam < ApplicationRecord
  FRAME_DOMAINS = Rails.configuration.content_security_policy_whitelisted_frame_domains
  IMAGE_LINK_EXTENSIONS = Set.new(['jpg', 'png', 'cgi', 'mjpg'])

  include UrlValidator

  belongs_to :airport

  has_many :actions, as: :actionable, dependent: :nullify

  has_paper_trail meta: {airport_id: :airport_id}

  after_create :create_tag
  after_destroy :remove_tag

  validates :url, uniqueness: {scope: :airport_id}

  def embedded?
    return image? || frame?
  end

  def image?
    uri = URI.parse(url)

    # Don't consider http:// links to be direct image links as that would cause mixed content loading on our HTTPS website
    return uri.is_a?(URI::HTTPS) && File.extname(uri.path)[1..]&.in?(IMAGE_LINK_EXTENSIONS)
  end

  def frame?
    uri = URI.parse(url)
    return uri.is_a?(URI::HTTPS) && uri.host.in?(FRAME_DOMAINS)
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
