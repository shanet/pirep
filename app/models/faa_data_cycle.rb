require 'faa/faa_api'

class FaaDataCycle < ApplicationRecord
  CURRENT = 'current'

  # This class is intended to be a singleton as the active FAA data cycles are a site-wide configuration
  private_class_method :new

  # Since this class is intended to be used in the Rails configuration this means that it will try to be loaded when the application
  # is initialized. However, in some cases (Rake tasks, tests, etc.) the database may not be connected or the table for this class
  # has not been created yet. Thus, we need to only attempt to hit the database once it's ready. Since this class a singleton that
  # means having a loader class which lazy loads anything from the database. This allows us to create the loader object when the
  # application initializes but nothing will hit the database until a method is explicitly called.
  class Loader
    def method_missing(method, *args, **kwargs, &block)
      return object.send(method, *args, **kwargs, &block)
    end

    def respond_to_missing?(method, include_private=false)
      return object.respond_to?(method, include_private)
    end

  private

    def object
      return @object ||= FaaDataCycle.instance
    end
  end

  def self.instance
    return first_or_create
  end

  def current(product, stub: !Rails.env.production?)
    # In development/test we don't want the assets to expire so always return a static string
    return CURRENT if stub

    # This is a long living object so we should reload it before getting the new data in the event that it was updated elsewhere
    reload

    # If there is no cached data cycle return the next one
    return send(product) || send(:next, product, stub: stub)
  end

  def next(product, stub: !Rails.env.production?)
    return CURRENT if stub

    # When downloading new data for the next cycle we don't want to use the cached values
    return FaaApi.client.current_data_cycle(product).iso8601
  end

  def update_data_cycles
    faa_api = FaaApi.client

    return update(
      airports: faa_api.current_data_cycle(:airports).iso8601,
      charts: faa_api.current_data_cycle(:charts).iso8601,
      diagrams: faa_api.current_data_cycle(:diagrams).iso8601
    )
  end

  def clear!
    return update(airports: nil, charts: nil, diagrams: nil)
  end
end
