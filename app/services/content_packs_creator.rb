class ContentPacksCreator
  include Rails.application.routes.url_helpers

  # Isolate parallel test runs with different filenames between processes
  DIRECTORY = "content_packs#{Rails.env.test? ? "_test_#{SecureRandom.uuid}" : ''}"

  # The color codes below are AABBGGRR. Why? KML likes to make life difficult for no reason.
  CONTENT_PACKS = {
    all_airports: {
      name: 'All Airports',
      icon: 'target.png',
      color: 'FFB1355E',
      tags: [:food, :lodging, :camping, :golfing],
      image: 'town.jpg',
      description: 'All of the airports from other content packs in one download.',
    },
    restaurants: {
      name: 'Restaurants',
      icon: 'square.png',
      color: 'FF4370FF',
      tags: [:food],
      image: 'content_pack_food.jpg',
      description: 'Airports to grab a bite to eat at. All restaurants are either on the field or within walking distance.',
    },
    lodging: {
      name: 'Lodging',
      icon: 'square.png',
      color: 'FF636E8D',
      tags: [:lodging],
      image: 'content_pack_lodging.jpg',
      description: 'Airports with a place to stay for the night. Either on the field or within walking distance.',
    },
    camping: {
      name: 'Camping',
      icon: 'square.png',
      color: 'FF6ABB66',
      tags: [:camping],
      image: 'content_pack_camping.jpg',
      description: 'Airports you can camp at or with a campground nearby.',
    },
    golfing: {
      name: 'Golfing',
      icon: 'square.png',
      color: 'FF65CC9C',
      tags: [:golfing],
      image: 'content_pack_golfing.jpg',
      description: 'Airports to play a round of golf at or nearby.',
    },
  }

  def initialize
    @controller = ApplicationController.new
  end

  def create_content_packs
    # Create a directory for the file if needed (this will be a normal directory in dev and a symlink to the EFS volume in production)
    FileUtils.mkdir_p(self.class.cache)
    FileUtils.mkdir_p(self.class.directory) if !File.exist?(self.class.directory) && !File.symlink?(self.class.directory)

    version = Time.zone.now.iso8601
    report = {}

    CONTENT_PACKS.each do |content_pack_id, content_pack_configuration|
      Rails.logger.info("Creating content pack version #{version} for #{content_pack_id}")

      content_pack_path = File.join(self.class.cache, "#{content_pack_id}.zip")
      report[content_pack_id] = create_content_pack(content_pack_id, content_pack_configuration, version, content_pack_path)

      # Move the content pack out of the working/cache directory and to live directory
      FileUtils.mv(content_pack_path, path_for_content_pack(content_pack_id, version))
    end

    delete_old_content_packs!(version)

    Rails.logger.info("Content pack rendering report: #{report}")
    return report
  end

  def create_content_pack(content_pack_id, content_pack_configuration, version, path)
    manifest = content_pack_manifest(content_pack_configuration[:name], version)
    airports = content_pack_airports(content_pack_configuration)
    directory_prefix = "pirep_#{content_pack_id}"
    render_queue = []

    kml = ApplicationController.render(template: 'content_packs/show', formats: :xml, assigns: {
      airports: airports,
      icon: (content_pack_id == :all_airports ? nil : content_pack_id), # Look up an icon for something more specific to differentiate by color
      name: manifest[:name],
    })

    # Any existing archive must be deleted first or new changes won't be reflected
    FileUtils.rm_f(path)

    Zip::File.open(path, create: true) do |archive|
      archive.get_output_stream("#{directory_prefix}/manifest.json") {|file| file.write(manifest.to_json)}
      archive.get_output_stream("#{directory_prefix}/navdata/#{manifest[:name]}.kml") {|file| file.write(kml)}

      # Find all airports that need to be rendered and make a config for them
      # Doing this as a batch per content pack saves the time of needing to start a Puppeteer browser process for each airport
      render_queue = []
      pdf_paths = {}

      airports.each do |airport|
        cached_path = airport_info_pdf_cached?(airport)

        if cached_path
          Rails.logger.info("Using cached airport info PDF for #{airport.code}")
          pdf_paths[airport.id] = cached_path
        else
          Rails.logger.info("Stale cached airport info PDF for #{airport.code}")
          pdf_paths[airport.id] = File.join(self.class.cache, "#{airport.code}_#{version}.pdf")

          render_queue << {
            url: airport_url(airport, host: "localhost:#{ENV.fetch('PORT', 3000)}", format: :snapshot),
            output: pdf_paths[airport.id],
          }
        end
      end

      Rails.logger.info('Rendering airport info PDFs')
      render_airport_info_pdfs(render_queue)

      # Add each of the rendered PDFs to the archive
      airports.each do |airport|
        Rails.logger.info("Adding #{airport.code} to content pack")
        archive.add("#{directory_prefix}/navdata/#{airport.icao_code || airport.code} Info.pdf", pdf_paths[airport.id])
      end
    end

    return {airports_rendered: render_queue.count}
  end

  def self.path_for_content_pack(content_pack_id)
    return Dir.glob(File.join(directory, "pirep_#{content_pack_id}_*.zip")).first
  end

  def self.content_pack_file_size(content_pack_id)
    path = path_for_content_pack(content_pack_id)
    return (path && File.exist?(path) ? File.size(path) : 0)
  end

  def self.content_pack_updated_at(content_pack_id)
    path = path_for_content_pack(content_pack_id)
    return (path ? Time.zone.parse(File.basename(path, '.*').split('_').last) : nil)
  end

  def self.content_pack?(content_pack_id)
    return !CONTENT_PACKS[content_pack_id&.to_sym].nil?
  end

  def self.airport_icon(airport)
    airport.tags.each do |tag|
      CONTENT_PACKS.each do |content_pack_id, content_pack_configuration|
        # Look for a more specific content pack first
        next if content_pack_id == :all_airports

        return content_pack_id if content_pack_configuration[:tags].include?(tag.name)
      end
    end

    return :all_airports
  end

  def self.icons
    return CONTENT_PACKS.reduce({}) do |icons, configuration|
      icons[configuration.first] = {color: configuration.last[:color], image: configuration.last[:icon]}
      next icons
    end
  end

private

  def content_pack_airports(content_pack_configuration)
    return Airport.includes(:tags).where(tags: {name: content_pack_configuration[:tags]})
  end

  def render_airport_info_pdfs(render_queue)
    render_queue_path = Rails.root.join('tmp/content_packs_render_queue.json')
    File.write(render_queue_path, render_queue.to_json)

    command = ['node', Rails.root.join('scripts/render_airport_info_pdf.js'), render_queue_path]
    status, output = ExternalCommandRunner.execute(*command)
    return if status.success?

    raise("Failed to render airport info PDFs: #{output}")
  end

  def content_pack_manifest(name, version)
    return {
      name: "Pirep - #{name}",
      abbreviation: "pirep_#{name.downcase.gsub(' ', '_')}",
      version: version,
      organizationName: 'Pirep.io',
    }
  end

  def delete_old_content_packs!(current_version)
    Dir.glob(File.join(self.class.directory, '*')).each do |file|
      next if current_version.in?(file)

      Rails.logger.info("Deleting old content pack: #{file}")
      File.unlink(file)
    end
  end

  def path_for_content_pack(content_pack_id, version)
    return File.join(self.class.directory, "pirep_#{content_pack_id}_#{version}.zip")
  end

  def airport_info_pdf_cached?(airport)
    # Try to find a cached PDF for the airport
    cached_path = Dir.glob(File.join(self.class.cache, "#{airport.code}_*.pdf")).first
    return false unless cached_path

    # The airport info PDF is cached if the timestamp in the filename is later than the last time the airport was updated
    timestamp = Time.zone.parse(File.basename(cached_path, '.*').split('_').last)

    return cached_path if timestamp > airport.updated_at

    Rails.logger.info("Deleting stale airport info PDF cache for #{airport.code}")
    FileUtils.rm_f(cached_path)
    return false
  end

  class << self
    def directory
      return File.join(File.join(*(Rails.configuration.try(:efs_path) || [Rails.public_path, 'assets'])), DIRECTORY) # rubocop:disable Rails/SafeNavigation
    end

    def cache
      return File.join(*(Rails.configuration.try(:efs_path) || [Rails.root, FaaApi::Service::CACHE_DIRECTORY, Rails.env, 'airport_info_pdfs'])) # rubocop:disable Rails/FilePath, Rails/SafeNavigation
    end
  end
end
