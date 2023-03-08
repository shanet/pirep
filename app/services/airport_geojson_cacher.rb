class AirportGeojsonCacher
  CACHE_KEY = 'airports_digest'

  def self.update_digest
    digest = SecureRandom.uuid

    # Expire the keys so the airports cache is updated periodically regardless of any changes
    Rails.cache.write(CACHE_KEY, digest, expires_in: 1.day)
    return digest
  end

  def self.read_digest
    digest = Rails.cache.fetch(CACHE_KEY)
    return digest if digest

    # If the cache expired or isn't set for any reason write a new one
    return update_digest
  end

  def self.clear!
    Rails.cache.delete(CACHE_KEY)
  end
end
