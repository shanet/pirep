require 'test_helper'

class AirportsHelperTest < ActionView::TestCase
  include AirportsHelper

  test 'version author' do
    unknown = create(:unknown)
    known = create(:known)

    with_versioning do
      version = create(:airport).versions.first

      # A nil whodunnit should return a default string
      assert_equal 'System', version_author(version)

      version.update!(whodunnit: unknown.id)
      assert manage_user_path(unknown).in?(version_author(version))

      version.update!(whodunnit: known.id)
      assert manage_user_path(known).in?(version_author(version))
    end
  end

  test 'diffs strings and arrays' do
    assert diff('foo', 'bar').left, 'Handled diff of strings'
    assert diff([{label: 'foo', latitude: 0, longitude: 0}], [{label: 'bar', latitude: 0, longitude: 0}]).left, 'Handled diff of annotations'
  end
end
