require 'test_helper'

class ContentPacksCreatorTest < ActiveSupport::TestCase
  test 'valid content pack?' do
    assert ContentPacksCreator.content_pack?(ContentPacksCreator::CONTENT_PACKS.keys.first), 'Reported valid content pack as invalid'
    assert_not ContentPacksCreator.content_pack?(:foobar), 'Reported invalid content pack as valid'
  end

  test 'icon for airport' do
    assert_equal :lodging, ContentPacksCreator.airport_icon(create(:airport, tags: [create(:tag, name: :lodging)])), 'Unexpected airport icon for lodging tag'
    assert_equal :all_airports, ContentPacksCreator.airport_icon(create(:airport, tags: [create(:tag, name: :museum)])), 'Unexpected airport icon for museum tag'
  end
end
