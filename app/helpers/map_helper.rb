module MapHelper
  def filter_icon(icon)
    return "<i class=\"fas fa-#{icon}\"></i>".html_safe
  end
end
