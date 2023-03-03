require 'securerandom'

ALL_CHARTS = 'All charts'

# rubocop:disable Rails/Output
class Seeds
  def initialize
    CLI::UI::StdoutRouter.enable
  end

  def perform
    # Log everything to stdout so progress can be monitored
    log_to_stdout!

    create_admin
    import_config = prompt_for_imports

    import_airports if import_config[:airports]
    import_diagrams if import_config[:diagrams]
    import_charts(:sectional, import_config[:charts][:sectional]) if import_config[:charts][:sectional].any?
    import_charts(:terminal, import_config[:charts][:terminal]) if import_config[:charts][:terminal].any?
  end

private

  def create_admin
    return puts CLI::UI.fmt("{{yellow:Admin account already exists, skipping admin creation\n}}") if Users::Admin.any?

    default_email = 'admin@example.com'
    default_password = SecureRandom.hex

    Users::Admin.create!(email: default_email, password: default_password, confirmed_at: Time.zone.now)

    CLI::UI::Frame.open('Admin user created') do
      puts CLI::UI.fmt("Email:    {{red:#{default_email}}}\nPassword: {{red:#{default_password}}}")
    end
  end

  def prompt_for_imports
    airports = CLI::UI.confirm('Import FAA airport database?')
    diagrams = CLI::UI.confirm('Import FAA airport diagrams?')

    puts CLI::UI.fmt("{{red:WARNING: Generating map tiles for all charts will take multiple hours. You may only want to select one or two charts for a development environment.}}\n")

    ask_for_sectionals = CLI::UI.confirm('Generate sectional chart map tiles?')
    sectionals = CLI::UI.ask('Which sectional charts?', options: chart_options(:sectional_charts), multiple: true) if ask_for_sectionals

    ask_for_terminals = CLI::UI.confirm('Generate terminal area chart map tiles?')
    terminals = CLI::UI.ask('Which terminal area charts?', options: chart_options(:terminal_area_charts), multiple: true) if ask_for_terminals

    return {
      airports: airports,
      diagrams: diagrams,
      charts: {
        sectional: sectionals || [],
        terminal: terminals || [],
      },
    }
  end

  def import_airports
    CLI::UI::Frame.open('Importing airports') do
      airports = AirportDatabaseParser.new.download_and_parse

      # Disable the bounding box calculation as we'll import those separately below
      AirportDatabaseImporter.new(airports, bounding_box_calculator: nil).load_database

      # Import the bounding boxes from a static file to avoid spamming OSM's servers with thousands of requests
      import_bounding_boxes
    end
  end

  def import_bounding_boxes
    bounding_boxes = YAML.safe_load(Rails.root.join('db/airport_bounding_boxes.yml').read)

    Airport.where(bbox_checked: false).find_each do |airport|
      bounding_box = bounding_boxes[airport.code]
      next unless bounding_box

      airport.update!(
        bbox_checked: true,
        bbox_ne_latitude: bounding_box[0],
        bbox_ne_longitude: bounding_box[1],
        bbox_sw_latitude: bounding_box[2],
        bbox_sw_longitude: bounding_box[3]
      )
    end
  end

  def import_diagrams
    CLI::UI::Frame.open('Importing diagrams') do
      AirportDiagramDownloader.new.download_and_convert
    end
  end

  def import_charts(chart_type, charts_to_download)
    # Send no kwargs to generate all charts
    if charts_to_download.include?(ALL_CHARTS)
      kwargs = {}
    else
      kwargs = {charts_to_download: charts_to_download}
    end

    CLI::UI::Frame.open("Generating #{chart_type} chart tiles") do
      ChartsDownloader.new.download_and_convert(chart_type, **kwargs)
    end
  end

  def chart_options(chart_type)
    return [ALL_CHARTS] + Rails.configuration.send(Rails.env.test? ? :test_charts : chart_type).keys.map(&:to_s).sort
  end

  def log_to_stdout!
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = Rails.configuration.log_formatter
    Rails.logger = ActiveSupport::TaggedLogging.new(logger)
  end
end
# rubocop:enable Rails/Output

# The tests will call this themselves
Seeds.new.perform unless Rails.env.test?
