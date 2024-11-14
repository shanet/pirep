require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test 'does not have non-addable tags' do
    nonaddable_tag = Tag::TAGS.find {|_key, value| !value[:addable]}.first
    assert_not Tag.addable_tags[nonaddable_tag], 'Non-addable tag included in addable tags list'
  end

  test 'does not have non-origin tags' do
    nonorigin_tag = Tag::TAGS.find {|_key, value| !value[:origin]}.first
    assert_not Tag.origin_tags[nonorigin_tag], 'Non-origin tag included in origin tags list'
  end

  test 'removes empty tag for airport on save' do
    airport = create(:airport, :empty)
    assert airport.tags.where(name: :empty), 'Empty tag on airport does not exist'

    # Creating a new tag for the airport should remove its empty tag
    create(:tag, airport: airport)
    assert airport.tags.where.not(name: :empty).any?, 'Empty tag on airport not removed'
  end

  test 'has label' do
    tag = create(:tag)
    assert_equal Tag::TAGS[tag.name.to_sym][:label], tag.label, 'Wrong label for tag'
  end
end
