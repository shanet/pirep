class Manage::DashboardController < ApplicationController
  def index
    authorize :dashboard, policy_class: Manage::DashboardPolicy
  end
end
