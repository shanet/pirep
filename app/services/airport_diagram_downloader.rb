require 'exceptions'
require 'faa/faa_api'

class AirportDiagramDownloader
  def download_and_convert
    Dir.mktmpdir do |directory|
      metadata_path = FaaApi.client.airport_diagrams(directory)

      diagrams = parse_archives(metadata_path)
      convert_diagrams_to_images(directory, diagrams)
      copy_diagrams(directory, diagrams)
    end

    return @airports
  end

private

  def parse_archives(metadata_path)
    # Parse the metadata file which contains the filenames for each airport's diagram
    xml = Nokogiri::XML(File.open(metadata_path)) do |config| # rubocop:disable Style/SymbolProc
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

      airport.update!(diagram: converted_diagram_filename(diagram_filename))
      diagram_filenames << diagram_filename
    end

    return diagram_filenames
  end

  def convert_diagrams_to_images(directory, diagrams)
    # Convert the PDFs to images so we can display them on the webpages
    diagrams.each_with_index do |file, index|
      path = File.join(directory, file)
      Rails.logger.info("[#{index}/#{diagrams.count}] Converting airport diagram #{path}")
      system('convert', '-flatten', '-density', '200', path, converted_diagram_filename(path))
    end
  end

  def copy_diagrams(directory, diagrams)
    diagrams.each_with_index do |file, index|
      filename = converted_diagram_filename(file)
      source_path = File.join(directory, filename)
      destination_path = "diagrams/#{Rails.configuration.faa_data_cycle.next(:diagrams)}"

      if Rails.env.production?
        key = File.join(Rails.configuration.cdn_content_path, destination_path, filename)
        Rails.logger.info("[#{index}/#{diagrams.count}] Uploading airport diagram to S3 with key #{key}")

        response = Aws::S3::Client.new.put_object(
          body: File.open(source_path, 'r'),
          bucket: Rails.configuration.asset_bucket,
          content_type: 'image/png',
          key: key
        )

        raise Exceptions::DiagramUploadFailed, response.to_h unless response.etag
      else
        diagrams_path = Rails.public_path.join('assets', destination_path)
        FileUtils.mkdir_p(diagrams_path)
        FileUtils.mv(source_path, File.join(diagrams_path, filename))
      end
    end
  end

  def converted_diagram_filename(file)
    return file.gsub(/\.PDF$/, '.png')
  end
end
