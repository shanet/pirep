class CommentPolicy < ApplicationPolicy
  def create?
    return !@user.disabled_at
  end

  def helpful?
    return !@user.disabled_at
  end

  def flag_outdated?
    return !@user.disabled_at
  end

  def undo_outdated?
    return !@user.disabled_at
  end

  def destroy?
    return admin?
  end
end
