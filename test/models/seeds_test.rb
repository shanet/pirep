require 'test_helper'
require Rails.root.join('db/seeds.rb')

class SeedsTest < ActiveSupport::TestCase
  teardown do
    # Clean up the tiles directory
    FileUtils.rm_rf(Rails.public_path.join('assets/tiles_test'))
  end

  test 'creates admin user' do
    assert_difference('Users::Admin.count') do
      run_seeds
    end

    # Running the seeds again should not create a second admin user
    assert_difference('Users::Admin.count', 0) do
      run_seeds
    end
  end

  test 'imports airports and diagrams' do
    assert_difference('Airport.count', 1) do
      run_seeds({import_airports: true, import_diagrams: true})
    end

    assert_in_delta(47.922902, Airport.first.bbox_ne_latitude, 0.1, 'NE latitude bounding box not imported from YAML file')
    assert_in_delta(-122.2691531, Airport.first.bbox_ne_longitude, 0.1, 'NE longitude bounding box not imported from YAML file')
    assert_in_delta(47.8966986, Airport.first.bbox_sw_latitude, 0.1, 'SW latitude bounding box not imported from YAML file')
    assert_in_delta(-122.2918449, Airport.first.bbox_sw_longitude, 0.1, 'SW longitude bounding box not imported from YAML file')

    assert_not_nil Airport.first.diagram, 'Airport diagram not imported'
  end

  test 'import charts' do
    assert_difference('Airport.count', 0) do
      run_seeds({import_sectional_charts: true, import_terminal_charts: true})
    end

    [:sectional, :terminal].each do |chart_type|
      assert Rails.root.join("public/assets/tiles_test/current/#{chart_type}").exist?, 'Did not generate map tiles'
    end
  end

private

  def run_seeds(seed_config={})
    input = []

    # Construct stdin to go through the menus per the given configuration
    [:import_airports, :import_diagrams, :import_sectional_charts, :import_terminal_charts].each do |key|
      # 1 = yes, 2 = no
      input << (seed_config[key] ? '1' : '2')

      if seed_config[key] && key.in?([:import_sectional_charts, :import_terminal_charts])
        # "1" for "all charts" and then "0" for "Done"
        input << '10'
      end
    end

    # Change stdin to write the input string constructed above and caputre stdout/stderr to not clutter up the test output
    stdin = StringIO.new(input.join)
    $stdin = stdin

    stdout = StringIO.new
    stderr = StringIO.new
    $stdout = stdout
    $stderr = stderr

    begin
      Seeds.new.perform
      $stdout = STDOUT
      $stderr = STDERR
    rescue
      $stdout = STDOUT
      $stderr = STDERR
      flunk "STDOUT:\n\n #{stdout.string}\nSTDERR:\n\n#{stderr.string}"
    end
  end
end
