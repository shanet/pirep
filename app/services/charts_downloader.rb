require 'etc'
require 'exceptions'
require 'open3'
require 'faa/faa_api'

class ChartsDownloader
  def download_and_convert(chart_type, charts_to_download=nil)
    verify_gdal_binaries_exist
    tiles_directory_prefix = "public/assets/tiles#{Rails.env.test? ? '_test' : ''}/#{chart_type}"

    Dir.mktmpdir do |tmp_directory|
      Dir.chdir(tmp_directory) do
        method = api_method_for_chart_type(chart_type)
        raise Exceptions::UnknownChartType unless method

        charts = FaaApi.client.send(method, tmp_directory, charts_to_download)

        charts.each do |chart_name, chart_image|
          convert_chart_to_tiles(chart_type, chart_name, chart_image, tmp_directory, tiles_directory_prefix)
        end
      end
    end

    Rails.logger.info('Swapping tiles directories')

    # Move the current tiles to a previous directory
    if File.exist?(Rails.root.join("#{tiles_directory_prefix}/current"))
      File.rename(Rails.root.join("#{tiles_directory_prefix}/current"), Rails.root.join("#{tiles_directory_prefix}/previous"))
    end

    # Swap in the new tiles
    File.rename(Rails.root.join("#{tiles_directory_prefix}/next"), Rails.root.join("#{tiles_directory_prefix}/current"))

    # Clean up the old tiles
    FileUtils.rm_rf(Rails.root.join("#{tiles_directory_prefix}/previous"))

    Rails.logger.info("#{chart_type.to_s.titleize} chart download complete")
  end

private

  def convert_chart_to_tiles(chart_type, chart_name, chart_image, input_directory, output_directory)
    Rails.logger.info("Generating map tiles for #{chart_type}/#{chart_name}")

    # The shapefile fixture to crop the chart to
    shapefile = FaaApi.client.chart_shapefile(chart_type, chart_name)

    # Intermediate files: the cropped chart the VRT file
    cropped_image = File.join(input_directory, "#{chart_name}_cropped.tif").to_s
    vrt_image = File.join(input_directory, "#{chart_name}.vrt").to_s

    # Create a directory for the chart's final generated tile files
    tiles_directory = Rails.root.join("#{output_directory}/next/#{chart_name}").to_s
    FileUtils.mkdir_p(tiles_directory)

    # Use all threads except one to not completely saturate the system
    threads = [Etc.nprocessors - 1, 1].max

    if File.exist?(shapefile)
      Rails.logger.info("Executing gdalwarp for chart #{chart_name}")

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
                             '-wo', "NUM_THREADS=#{threads}",
                             '-multi',
                             '-overwrite',
                             chart_image,
                             cropped_image)

        raise Exceptions::ChartTilesGenerationFailed, "gdalwarp for #{chart_name}"
      end
    else
      Rails.logger.info("Shapefile for #{chart_name} does not exist, using full chart image")
      cropped_image = chart_image
    end

    Rails.logger.info("Executing gdal_translate for chart #{chart_name}")
    unless execute_command('gdal_translate', '-of', 'vrt', '-expand', 'rgba', cropped_image, vrt_image)
      raise Exceptions::ChartTilesGenerationFailed, "gdal_translate for #{chart_name}"
    end

    Rails.logger.info("Executing gdal2tiles.py for chart #{chart_name}")
    unless execute_command('gdal2tiles.py', '--zoom', "#{min_zoom_level(chart_type)}-11", "--processes=#{threads}", '--webviewer=none', vrt_image, tiles_directory) # rubocop:disable Style/GuardClause
      raise Exceptions::ChartTilesGenerationFailed, "gdal2tiles.py for #{chart_name}"
    end
  end

  def execute_command(*command)
    stdout_stderr, status = Open3.capture2e(*command)

    unless status.success?
      Rails.logger.error("Failed to run command: #{command.join(' ')}")
      Rails.logger.error(stdout_stderr)
      return false
    end

    return true
  end

  def verify_gdal_binaries_exist
    ['gdalwarp', 'gdal_translate', 'gdal2tiles.py'].each do |binary|
      unless system("which #{binary} &> /dev/null")
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
end
