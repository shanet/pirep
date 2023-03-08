class MetaPolicy < ApplicationPolicy
  def health?
    return true
  end

  def sitemap?
    return true
  end
end
