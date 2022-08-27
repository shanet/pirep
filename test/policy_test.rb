require 'test_helper'

class PolicyTest < ActiveSupport::TestCase
  def assert_allows(user, record, action, message=nil)
    assert execute_policy(user, record, action), message
  end

  def assert_denies(user, record, action, message=nil)
    assert_not execute_policy(user, record, action), message
  end

  # Allows only admins
  def assert_allows_admin(record, action)
    assert_allows :admin, record, action, "Denied admin to #{record}/#{action}"
    assert_denies :known, record, action, "Allowed user to #{record}/#{action}"
    assert_denies nil, record, action, "Allowed anonymous to #{record}/#{action}"
  end

  # Allows all logged in users
  def assert_allows_users(record, action)
    assert_allows :admin, record, action, "Denied admin to #{record}/#{action}"
    assert_allows :known, record, action, "Denied user to #{record}/#{action}"
    assert_denies nil, record, action, "Allowed anonymous to #{record}/#{action}"
  end

  # Allows everyone, including anonymous users
  def assert_allows_all(record, action)
    assert_allows nil, record, action, "Denied anonymous to #{record}/#{action}"
    assert_allows :admin, record, action, "Denied admin to #{record}/#{action}"
    assert_allows :known, record, action, "Denied user to #{record}/#{action}"
  end

  # Denies everyone, including anonymous users
  def assert_denies_all(record, action)
    assert_denies nil, record, action, "Allowed anonymous to #{record}/#{action}"
    assert_denies :admin, record, action, "Allowed admin to #{record}/#{action}"
    assert_denies :known, record, action, "Allowed user to #{record}/#{action}"
  end

private

  def execute_policy(user, record, action)
    user = (!user || user.is_a?(Users::User) ? user : create(user)) # rubocop:disable Rails/SaveBang

    klass = self.class.to_s.gsub(/Test$/, '').constantize
    return klass.new(user, record).send("#{action}?")
  end
end
