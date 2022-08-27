class CommentPolicy < ApplicationPolicy
  def create?
    return true
  end

  def helpful?
    return true
  end

  def flag_outdated?
    return true
  end

  def undo_outdated?
    return true
  end
end
