require 'exceptions'
require 'zip'

class AirportDiagramDownloader
  # There are five archive files to download from the FAA containing all airport diagrams and procedures
  # https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dtpp/
  ARCHIVES = ['A', 'B', 'C', 'D', 'E']

  def initialize
  end

  def download_and_convert
    Dir.mktmpdir do |directory|
      ARCHIVES.each do |archive|
        download_archive(archive, directory)
      end

      diagrams = parse_archives(directory)
      convert_diagrams_to_images(directory, diagrams)
      copy_diagrams(directory, diagrams)
    end

    return @airports
  end

private

  def download_archive(archive, directory)
    # url = 'https://aeronav.faa.gov/upload_313-d/terminal/DDTPP%s_%s.zip' % [archive, current_data_cycle.strftime('%y%m%d')])
    url = 'http://localhost:3000/assets/archives/DDTPP%s_%s.zip' % [archive, current_data_cycle.strftime('%y%m%d')]

    Rails.logger.info('Downloading archive %s to %s ' % [url, directory])
    response = Faraday.get(url)
    raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

    # Write archive to disk
    archive_path = File.join(directory, 'archive_%s.zip' % archive)
    File.open(archive_path, 'wb') {|file| file.write(response.body)}

    Rails.logger.info('Extracting archive %s to %s ' % [url, directory])

    Zip::File.open(archive_path) do |archive|
      # Extract each file in the archive
      archive.each do |file|
        path = File.join(directory, file.name)
        archive.extract(file, path)
      end
    end
  end

  def parse_archives(directory)
    # Parse the metadata file which contains the filenames for each airport's diagram
    metadata = File.join(directory, 'd-TPP_Metafile.xml')

    xml = Nokogiri::XML(File.open(metadata)) do |config|
      config.strict
    end

    # Get all of the airport diagram nodes
    airport_diagrams = xml.xpath('//record/chart_name[text() = "AIRPORT DIAGRAM"]')
    diagram_filenames = []

    # Get the airport code and diagram filename for each airport and update its record
    airport_diagrams.each do |node|
      record_node = node.parent
      airport_node = record_node.parent

      airport_code = airport_node['apt_ident']
      diagram_filename = record_node.xpath('pdf_name/text()').to_s

      airport = Airport.find_by(code: airport_code)
      next Rails.logger.error('Airport not found: %s' % airport_code) unless airport

      airport.update(diagram: converted_diagram_filename(diagram_filename))
      diagram_filenames << diagram_filename
    end

    return diagram_filenames
  end

  def convert_diagrams_to_images(directory, diagrams)
    # Convert the PDFs to images so we can display them on the webpages
    diagrams.each do |file|
      path = File.join(directory, file)
      Rails.logger.info('Converting airport diagram %s' % path)
      `convert -flatten -density 200 #{path} #{converted_diagram_filename(path)}`
    end
  end

  def copy_diagrams(directory, diagrams)
    diagrams.each do |file|
      filename = converted_diagram_filename(file)
      path = File.join(directory, filename)

      if Rails.env.production?
        # TODO: upload to s3
      else
        FileUtils.mv(path, Rails.root.join('public/assets/diagrams/', filename))
      end
    end
  end

  def converted_diagram_filename(file)
    return file.gsub(/\.PDF$/, '.png')
  end

  def current_data_cycle
    # New data is available every 28 days
    cycle_length = 28.days
    next_cycle = Date.new(2020, 9, 10)

    # Iterate from the start cycle until we hit the current date than back up one cycle for the current one
    next_cycle += cycle_length while Date.current >= next_cycle

    return next_cycle - cycle_length
  end
end
