class MetaController < ApplicationController
  # Health checks and sitemap requests should not track users
  skip_before_action :touch_user_seen, only: [:health, :sitemap]

  def health
    authorize :health, policy_class: MetaPolicy
    head :ok
  end

  def sitemap
    authorize :sitemap, policy_class: MetaPolicy
    response.headers['Content-Type'] = 'text/xml'
    render :sitemap, layout: false, formats: [:xml]
  end

private

  def pundit_user
    return nil
  end
end
