require 'test_helper'

class VersionsCollatorTest < ActiveSupport::TestCase
  setup do
    with_versioning do
      @airport = create(:airport)
      @description = @airport.description
      @wifi = @airport.wifi

      @user1 = create(:unknown)
      @user2 = create(:known)
    end
  end

  test 'collates versions' do
    with_versioning do
      # Create some versions to test against
      15.times do |i|
        # Change an extra field mid-way through to test if it gets added to the changes hash in the collated version
        @airport.update!((i == 8 ? {description: i + 1, wifi: 'changed'} : {description: i + 1}))
      end

      # Change the initial create versions (one for the initial create + one for the airport photo the factory adds through an update) to be created well in the past
      @airport.versions[0].update!(created_at: (VersionsCollator::PERIOD + 1.hour).ago)
      @airport.versions[1].update!(created_at: (VersionsCollator::PERIOD + 1.hour - 1.second).ago)

      @airport.versions[2..3].each do |version|
        version.update!(created_at: (VersionsCollator::PERIOD + 1.second).ago, whodunnit: @user1.id)
      end

      @airport.versions[4..5].each do |version|
        version.update!(whodunnit: @user1.id)
      end

      @airport.versions[9].update!(whodunnit: @user1.id)

      [@airport.versions[6..8], @airport.versions[10..]].flatten.each do |version|
        version.update!(whodunnit: @user2.id)
      end

      VersionsCollator.new(@airport).collate!
      @airport.reload

      assert_equal 7, @airport.versions.count, 'Incorrect number of collated versions'

      # The initial create versions should be unchanged
      assert_equal 'create', @airport.versions[0].event, 'Initial create version not preserved'
      assert_nil @airport.versions[1].whodunnit, 'Initial create version not preserved'

      # The first update version should be the original description changing to the second update
      assert_equal @description, @airport.versions[2].object_changes['description'].first, 'Incorrect object changes on collated version'
      assert_equal '2', @airport.versions[2].object_changes['description'].last, 'Incorrect object changes on collated version'
      assert_equal @user1.id, @airport.versions[2].whodunnit, 'User not preserved on collated version'

      # The second update version should be seperate from the first update version as it's more than the collate period from the previous update
      assert_equal '2', @airport.versions[3].object_changes['description'].first, 'Incorrect object changes on collated version'
      assert_equal '4', @airport.versions[3].object_changes['description'].last, 'Incorrect object changes on collated version'
      assert_equal @user1.id, @airport.versions[3].whodunnit, 'User not preserved on collated version'

      # The third update version should be separate from the previous and next versions since it was made by a different user
      assert_equal '4', @airport.versions[4].object_changes['description'].first, 'Incorrect object changes on collated version'
      assert_equal '7', @airport.versions[4].object_changes['description'].last, 'Incorrect object changes on collated version'
      assert_equal @user2.id, @airport.versions[4].whodunnit, 'User not preserved on collated version'

      # The fourth update version should be separate from the preivous version as it's a different user
      assert_equal '7', @airport.versions[5].object_changes['description'].first, 'Incorrect object changes on collated version'
      assert_equal '8', @airport.versions[5].object_changes['description'].last, 'Incorrect object changes on collated version'
      assert_equal @user1.id, @airport.versions[5].whodunnit, 'User not preserved on collated version'

      # The fifth update version should pick up changes from a different field made in the middle of the updates
      assert_equal '8', @airport.versions[6].object_changes['description'].first, 'Incorrect object changes on collated version'
      assert_equal '15', @airport.versions[6].object_changes['description'].last, 'Incorrect object changes on collated version'
      assert_equal @wifi, @airport.versions[6].object_changes['wifi'].first, 'Incorrect object changes on collated version'
      assert_equal 'changed', @airport.versions[6].object_changes['wifi'].last, 'Incorrect object changes on collated version'
      assert_equal @user2.id, @airport.versions[6].whodunnit, 'User not preserved on collated version'
    end
  end

  test 'collates with a single version' do
    with_versioning do
      # Sanity check that it works with collating a single version
      @airport.update!(description: 'changed')
      @airport.versions.last.update!(whodunnit: @user1.id)

      VersionsCollator.new(@airport).collate!
      assert_equal 3, @airport.reload.versions.count, 'Versions incorrectly collated'
    end
  end

  test 'collates versions with associated actions' do
    with_versioning do
      collation_start_version = @airport.versions.last

      # Create two versions to be collated together
      @airport.update!(description: 'update 1')
      @airport.update!(description: 'update 2')

      # Create an action that belongs to the last version which will be deleted in collation
      action = create(:action, actionable: @airport, version: @airport.versions.last)

      VersionsCollator.new(@airport).collate!
      assert_equal collation_start_version, action.reload.version, 'Action version reference not updated in version collation'
    end
  end
end
