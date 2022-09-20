class Manage::DashboardController < ApplicationController
  def index
    authorize :dashboard, policy_class: Manage::DashboardPolicy
  end

  def activity
    authorize :activity, policy_class: Manage::DashboardPolicy
  end
end
