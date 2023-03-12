class AirportGeojsonDumper
  # Isolate parallel test runs with different filenames between processes
  DIRECTORY = "airports_cache#{Rails.env.test? ? "_test_#{SecureRandom.uuid}" : ''}"
  FILENAME_PATTERN = 'airports-*.json'

  # Disable caching of airport geojson in test since even though the cache file is isolated per-process
  # above, leaving old data from one test in the cache will cause difficult to track down problems
  @enabled = !Rails.env.test?

  class << self
    attr_accessor :enabled
  end

  def write_to_file
    geojson = Airport.geojson.to_json

    directory = cache_directory
    digest = Digest::SHA256.hexdigest(geojson)
    filename = FILENAME_PATTERN.gsub('*', digest)

    path = File.join(directory, filename).to_s
    Rails.logger.info("Writing airports cache: #{path}")

    # Create a directory for the file if needed (this will be a normal directory in dev and a symlink to the EFS volume in production)
    FileUtils.mkdir_p(directory) if !File.exist?(directory) && !File.symlink?(directory)

    if File.exist?(path)
      Rails.logger.info('Airports cache unchanged, skipping write')
    else
      File.write(path, geojson)
    end

    # Delete old files; there should only be the most recent dump present on the filesystem
    cleanup_cache!(path)

    return self.class.cached
  end

  def self.cached
    return nil unless @enabled

    return Rails.public_path.join('assets', DIRECTORY).glob(FILENAME_PATTERN).first&.to_s&.gsub(Rails.public_path.to_s, '')
  end

  def clear_cache!
    FileUtils.rm_rf(cache_directory)
  end

private

  def cache_directory
    return File.join(File.join(*(Rails.configuration.try(:efs_path) || [Rails.public_path, 'assets'])), DIRECTORY) # rubocop:disable Rails/SafeNavigation
  end

  def cleanup_cache!(current)
    Dir.glob(File.join(File.dirname(current), FILENAME_PATTERN)).each do |file|
      next if file == current

      Rails.logger.info("Deleting old airports cache: #{file}")
      File.delete(file)
    end
  end
end
