class MetaPolicy < ApplicationPolicy
  def about?
    return true
  end

  def health?
    return true
  end

  def sitemap?
    return true
  end
end
