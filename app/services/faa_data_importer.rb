class FaaDataImporter
  def initialize(force_update: false)
    @force_update = force_update
  end

  def import!
    [:airports, :diagrams, :charts].each do |product|
      import_product!(product)
    end

    Rails.logger.info('Activating new data cycles')
    activate_content!
  end

private

  def import_product!(product)
    method = "import_#{product}"

    Rails.logger.tagged(method) do
      unless product_needs_update?(product)
        Rails.logger.info("#{product} not due for update, skipping")
        return
      end

      Rails.logger.info("Starting import for #{product}")
      send(method)
    end
  end

  def import_airports
    airports = AirportDatabaseParser.new.download_and_parse
    AirportDatabaseImporter.new(airports).load_database
  end

  def import_diagrams
    AirportDiagramDownloader.new.download_and_convert
  end

  def import_charts
    [:sectional, :terminal].each do |chart_type|
      ChartsDownloader.new.download_and_convert(chart_type)
    end
  end

  def activate_content!
    # Write the current data cycles to the cache to make them active
    Rails.configuration.faa_data_cycle.update_data_cycles
  end

  def product_needs_update?(product)
    return true if @force_update

    return Rails.configuration.faa_data_cycle.current(product) != Rails.configuration.faa_data_cycle.next(product)
  end
end
