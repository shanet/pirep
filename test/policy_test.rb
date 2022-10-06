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

  def assert_scope(allowed_users, denied_users, records, model)
    scope_class = "#{self.class.name.gsub(/Test$/, '')}::Scope".constantize

    allowed_users.each do |user|
      user = create_user(user)
      scoped_records = scope_class.new(user, model.all).resolve

      records.each do |record|
        assert record.in?(scoped_records), "Denied #{user.type} access to scoped record"
      end
    end

    denied_users.each do |user|
      user = create_user(user)
      scoped_records = scope_class.new(user, model.all).resolve

      records.each do |record|
        assert_not record.in?(scoped_records), "Allowed #{user.type} access to scoped record"
      end
    end
  end

private

  def execute_policy(user, record, action, disabled_user: false)
    user = create_user(user, disabled_user: disabled_user)
    klass = self.class.name.gsub(/Test$/, '').constantize

    return klass.new(user, record).send("#{action}?")
  end

  def create_user(user_or_type, disabled_user: false)
    return user_or_type if user_or_type.is_a? Users::User

    return create(user_or_type, disabled_at: (disabled_user ? Time.zone.now : nil))
  end
end
