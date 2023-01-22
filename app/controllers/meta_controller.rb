class MetaController < ApplicationController
  # Health checks should not track users
  skip_before_action :touch_user, only: :health

  def health
    authorize :meta
    head :ok
  end

private

  def pundit_user
    return nil
  end
end
