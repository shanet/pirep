require 'test_helper'

class ReadOnlyTest < ActiveSupport::TestCase
  setup do
    # Since the ReadOnly instance on the Rails.configuration is a lazy loading object we need to
    # directly call the instance here at least once so it will create the database record if
    # necessary. Otherwise, not having the database record created will result in inconsistent
    # test failures on the test below which checks if calling this method does not create
    # a new database record depending on the test run order.
    ReadOnly.instance
  end

  teardown do
    # Ensure that we always have read only mode disabled regardless of what a test does here
    Rails.configuration.read_only.disable!
  end

  test 'getting instance does not create a new record' do
    assert_difference('ReadOnly.count', 0) do
      ReadOnly::Loader.new.enabled?
      ReadOnly.instance
    end
  end

  test 'cannot call new method of singleton' do
    assert_raises(NoMethodError) do
      ReadOnly.new
    end
  end

  test 'enable read only mode' do
    Rails.configuration.read_only.enable!
    assert Rails.configuration.read_only.enabled?, 'Read only mode not enabled'
  end

  test 'disable read only mode' do
    Rails.configuration.read_only.disable!
    assert Rails.configuration.read_only.disabled?, 'Read only mode not disabled'
  end
end
