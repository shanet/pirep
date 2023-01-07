require 'etc'
require 'exceptions'
require 'open3'
require 'faa/faa_api'

class ChartsDownloader
  def download_and_convert(chart_type, charts_to_download=nil)
    verify_gdal_binaries_exist
    tiles_directory_prefix = "public/assets/tiles#{Rails.env.test? ? '_test' : ''}/#{chart_type}"

    Dir.mktmpdir do |tmp_directory|
      method = api_method_for_chart_type(chart_type)
      raise Exceptions::UnknownChartType unless method

      charts = FaaApi.client.send(method, tmp_directory, charts_to_download)

      vrt_files = charts.map do |chart_name, chart_image|
        preprocess_chart_for_tiles(chart_type, chart_name, chart_image, tmp_directory)
      end

      generate_tiles_for_chart_type(chart_type, vrt_files, tmp_directory, Rails.root.join("#{tiles_directory_prefix}/next").to_s)
    end

    activate_new_tiles(tiles_directory_prefix)
    Rails.logger.info("#{chart_type.to_s.titleize} chart download complete")
  end

private

  def preprocess_chart_for_tiles(chart_type, chart_name, chart_path, input_directory)
    cropped_chart_path = crop_chart(chart_type, chart_name, chart_path, input_directory)
    return generate_chart_vrt(chart_type, chart_name, cropped_chart_path, input_directory)
  end

  def crop_chart(chart_type, chart_name, chart_path, input_directory)
    # The shapefile fixture to crop the chart to
    shapefile = FaaApi.client.chart_shapefile(chart_type, chart_name)

    unless File.exist?(shapefile)
      Rails.logger.info("Shapefile for #{chart_name} does not exist, using full chart image")
      return chart_path
    end

    Rails.logger.info("Executing gdalwarp for chart #{chart_type}/#{chart_name}")
    cropped_chart_path = File.join(input_directory, "#{chart_name}_cropped.tif").to_s

    # It's not entirely clear to me why this is, but the eastern half of the Western Aleutian Islands chart crosses the antimeridian
    # gdal's tooling doesn't handle this well and even though I split this chart into two parts on each side of the antimeridian, it
    # still hits the problem described here: https://gis.stackexchange.com/questions/380002/issue-creating-tiles-from-geotiff-which-crosses-the-180th-meridian/
    # As such, we need to specify the target spatial reference explicitly in order to not have extremely low resolution tiles.
    unless execute_command('gdalwarp',
                           '-t_srs', 'EPSG:3857',
                           '-co', 'TILED=YES',
                           '-dstalpha',
                           '-of', 'GTiff',
                           '-cutline', shapefile,
                           '-crop_to_cutline',
                           '-wo', "NUM_THREADS=#{thread_count}",
                           '-multi',
                           '-overwrite',
                           chart_path,
                           cropped_chart_path)

      raise Exceptions::ChartTilesGenerationFailed, "gdalwarp for #{chart_name}"
    end

    return cropped_chart_path
  end

  def generate_chart_vrt(chart_type, chart_name, chart_path, input_directory)
    vrt_path = File.join(input_directory, "#{chart_name}.vrt").to_s

    Rails.logger.info("Executing gdal_translate for chart #{chart_type}/#{chart_name}")
    unless execute_command('gdal_translate', '-of', 'vrt', '-expand', 'rgba', chart_path, vrt_path)
      raise Exceptions::ChartTilesGenerationFailed, "gdal_translate for #{chart_type}/#{chart_name}"
    end

    return vrt_path
  end

  def generate_tiles_for_chart_type(chart_type, vrt_files, input_directory, output_directory)
    vrt_path = File.join(input_directory, "#{chart_type}_combined.vrt").to_s

    Rails.logger.info("Executing gdalbuildvrt for #{chart_type} charts")
    unless execute_command('gdalbuildvrt', vrt_path, *vrt_files)
      raise Exceptions::ChartTilesGenerationFailed, "gdalbuildvrt for #{chart_type}"
    end

    # Create a directory for the chart's final generated tile files
    FileUtils.mkdir_p(output_directory)

    Rails.logger.info("Executing gdal2tiles.py for #{chart_type} charts")
    unless execute_command('gdal2tiles.py', '--zoom', "#{min_zoom_level(chart_type)}-11", "--processes=#{thread_count}", '--webviewer=none', vrt_path, output_directory) # rubocop:disable Style/GuardClause
      raise Exceptions::ChartTilesGenerationFailed, "gdal2tiles.py for #{chart_type}"
    end
  end

  def activate_new_tiles(tiles_directory_prefix)
    Rails.logger.info('Swapping tiles directories')

    # Move the current tiles to a previous directory
    if File.exist?(Rails.root.join("#{tiles_directory_prefix}/current"))
      File.rename(Rails.root.join("#{tiles_directory_prefix}/current"), Rails.root.join("#{tiles_directory_prefix}/previous"))
    end

    # Swap in the new tiles
    File.rename(Rails.root.join("#{tiles_directory_prefix}/next"), Rails.root.join("#{tiles_directory_prefix}/current"))

    # Clean up the old tiles
    FileUtils.rm_rf(Rails.root.join("#{tiles_directory_prefix}/previous"))
  end

  def execute_command(*command)
    stdout_stderr, status = Open3.capture2e(*command)

    unless status.success?
      Rails.logger.error("Failed to run command: #{command.join(' ')}")

      # Print to stdout for tests so it's more obvious what the failure was
      Rails.env.test? ? puts(stdout_stderr) : Rails.logger.error(stdout_stderr) # rubocop:disable Rails/Output

      return false
    end

    return true
  end

  def verify_gdal_binaries_exist
    ['gdalwarp', 'gdal_translate', 'gdalbuildvrt', 'gdal2tiles.py'].each do |binary|
      unless system("which #{binary} > /dev/null 2>&1")
        Rails.logger.error("#{binary} binary not found, ensure that it exists and is in your $PATH")
        raise Exceptions::GdalBinaryNotFound, binary
      end
    end
  end

  def api_method_for_chart_type(chart_type)
    return {
      sectional: :sectional_charts,
      terminal: :terminal_area_charts,
      caribbean: :caribbean_charts,
      **(Rails.env.test? ? {test: :test_charts} : {}),
    }[chart_type]
  end

  def min_zoom_level(chart_type)
    # Terminal area charts are only shown when zoomed in to a sufficient degree. All other charts should be visible out to zoom level 0.
    return (chart_type == :terminal ? 10 : 0)
  end

  def thread_count
    # Use all threads except one to not completely saturate the system
    return [Etc.nprocessors - 1, 1].max
  end
end