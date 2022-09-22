require 'test_helper'

class PolicyTest < ActiveSupport::TestCase
  def assert_allows(user, record, action, message=nil, disabled_user: false)
    assert execute_policy(user, record, action, disabled_user: disabled_user), message
  end

  def assert_denies(user, record, action, message=nil, disabled_user: false)
    assert_not execute_policy(user, record, action, disabled_user: disabled_user), message
  end

  # Allows only admins
  def assert_allows_admin(record, action)
    assert_allows :admin, record, action, "Denied admin to #{record}/#{action}"
    assert_denies :known, record, action, "Allowed known user to #{record}/#{action}"
    assert_denies :unknown, record, action, "Allowed unknown user to #{record}/#{action}"
  end

  # Allows all logged in users
  def assert_allows_users(record, action, allow_disabled: true)
    assert_denies :unknown, record, action, "Allowed unknown user to #{record}/#{action}"
    assert_allows :known, record, action, "Denied known user to #{record}/#{action}"
    assert_allows :admin, record, action, "Denied admin to #{record}/#{action}"

    # Check that disabled users are allowed/denied based on the flag
    if allow_disabled
      assert_allows :known, record, action, "Denied known disabled to #{record}/#{action}", disabled_user: true
    else
      assert_denies :known, record, action, "Allowed known disabled known user to #{record}/#{action}", disabled_user: true
    end
  end

  # Allows everyone, including unknown users
  def assert_allows_all(record, action, allow_disabled: true)
    assert_allows :unknown, record, action, "Denied unknown user to #{record}/#{action}"
    assert_allows :known, record, action, "Denied known user to #{record}/#{action}"
    assert_allows :admin, record, action, "Denied admin to #{record}/#{action}"

    # Check that disabled users are allowed/denied based on the flag
    if allow_disabled
      assert_allows :unknown, record, action, "Denied unknown disabled to #{record}/#{action}", disabled_user: true
      assert_allows :known, record, action, "Denied known disabled to #{record}/#{action}", disabled_user: true
    else
      assert_denies :unknown, record, action, "Allowed unknown disabled known user to #{record}/#{action}", disabled_user: true
      assert_denies :known, record, action, "Allowed known disabled known user to #{record}/#{action}", disabled_user: true
    end
  end

  # Denies everyone, including unknown users
  def assert_denies_all(record, action)
    assert_denies :unknown, record, action, "Allowed unknown user to #{record}/#{action}"
    assert_denies :known, record, action, "Allowed known user to #{record}/#{action}"
    assert_denies :admin, record, action, "Allowed admin to #{record}/#{action}"
  end

private

  def execute_policy(user, record, action, disabled_user: false)
    unless user.is_a? Users::User
      user = create(user, disabled_at: (disabled_user ? Time.zone.now : nil))
    end

    klass = self.class.to_s.gsub(/Test$/, '').constantize
    return klass.new(user, record).send("#{action}?")
  end
end
