class RackAttackCacheCleanerJob < ApplicationJob
  def perform
    Rack::Attack.cache.store.cleanup
  end
end
