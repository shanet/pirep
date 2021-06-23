require 'test_helper'

class RunwayTest < ActiveSupport::TestCase
  setup do
    @runway = create(:runway)
  end

  test 'length threat level' do
    lengths = [
      [-1000, 'red'],
      [1999, 'red'],
      [2000, 'orange'],
      [2999, 'orange'],
      [3000, 'green'],
      [10000, 'green'],
    ]

    lengths.each do |length|
      @runway.update! length: length.first
      assert_equal length.last, @runway.length_threat_level, 'Unexpected length threat level for %s' % length.first
    end
  end
end
