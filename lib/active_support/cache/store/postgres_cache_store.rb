require 'monitor'

# Implementation of Rails' cache store interface to store cache keys as
# Postgres records since there's no support for database caching otherwise.
# See https://api.rubyonrails.org/v7.0.4/classes/ActiveSupport/Cache/Store.html
#
# This is probably a really bad idea to use Postgres as a cache but I only need a
# cache for Rack::Attack values and I don't want to pay for a Redis instance just for
# that. This uses the database instead which should be fine for a while and if/when
# a dedicated Redis instance is needed we can easily swap out the cache store class.
module ActiveSupport
  module Cache
    class PostgresCacheStore < Store
      def initialize(options={})
        super

        @model = CacheModel
        @monitor = Monitor.new
      end

      def increment(name, amount=1, **options)
        options = merged_options(options)

        synchronize do
          value = read(name, **options)&.to_i
          return nil unless value

          value += amount
          write(name, value, **options)
          return value
        end
      end

      def decrement(name, amount=1, **options)
        return increment(name, -amount, **options)
      end

      def size
        return @model.cache_size
      end

      # Delete all cache values
      def clear(*)
        @model.truncate!
      end

      # Deletes all keys that have expired
      def cleanup(*) # rubocop:disable Naming/PredicateMethod
        @model.expired_records.each do |record|
          delete_entry(record.key)
        end

        return true
      end

      # Tell Rails that this class supports cache versions
      def self.supports_cache_versioning?
        return true
      end

    private

      def write_entry(key, entry, **options) # rubocop:disable Naming/PredicateMethod
        # Seralize the entry per Rails' cache store class before writing it to the database
        payload = serialize_entry(entry, **options)
        @model.write(key, payload, entry)
        return true
      end

      def read_entry(key, **_options)
        # Read the key and deseralized the value per Rails' cache store class
        payload = @model.read(key)
        return deserialize_entry(payload)
      end

      def delete_entry(key, **_options)
        @model.delete(key)
      end

      def synchronize(&block)
        @monitor.synchronize(&block)
      end

      class CacheModel < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
        self.table_name = 'postgres_cache_store'

        def self.write(key, value, entry)
          # Rails will used the seralized entry when the cache key is read back but also store the entry as a JSONB
          # column so we can easily check it's expiration time and also have a more easily readable version as well.
          return upsert({key: key, value: connection.escape_bytea(value), entry: entry}, unique_by: [:key]) # rubocop:disable Rails/SkipsModelValidations
        end

        def self.read(key)
          return connection.unescape_bytea(find_by(key: key)&.value)
        end

        def self.delete(key)
          return destroy_by(key: key)
        end

        def self.expired_records
          return where('CAST(entry->>\'expires_in\' as float) < ?', Time.zone.now.to_i)
        end

        def self.truncate!
          connection.truncate(table_name)
        end

        def self.cache_size
          return count
        end
      end
    end
  end
end
