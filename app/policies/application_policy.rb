# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    return false
  end

  def show?
    return false
  end

  def create?
    return false
  end

  def new?
    return create?
  end

  def update?
    return false
  end

  def edit?
    return update?
  end

  def destroy?
    return false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

  private

    attr_reader :user, :scope
  end

private

  def admin?
    return @user&.admin?
  end

  def unknown?
    return @user&.unknown?
  end
end
