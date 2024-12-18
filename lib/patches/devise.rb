raise('Remove this patch once Devise is updated') if Rails.version >= '8.1'

module Devise
  def self.mappings
    Rails.application.reload_routes_unless_loaded

    @@mappings
  end
end
