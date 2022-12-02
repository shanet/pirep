class Manage::DashboardController < ApplicationController
  def index
    authorize :dashboard, policy_class: Manage::DashboardPolicy
    flash.now[:error] = 'Read only mode is enabled' if Rails.configuration.read_only.enabled?
  end

  def activity
    authorize :activity, policy_class: Manage::DashboardPolicy

    @limit = 10

    @active_airports = {
      all_time: most_active_records(Airport, :actionable_id, @limit),
      month: most_active_records(Airport, :actionable_id, @limit, 1.month.ago),
    }

    @active_users = {
      all_time: most_active_records(Users::User, :user_id, @limit),
      month: most_active_records(Users::User, :user_id, @limit, 1.month.ago),
    }
  end

  def update_read_only
    authorize :update_read_only, policy_class: Manage::DashboardPolicy

    if params[:read_only] == 'true'
      Rails.configuration.read_only.enable!
      redirect_to manage_root_path
    else
      Rails.configuration.read_only.disable!
      redirect_to manage_root_path, notice: 'Read only mode has been disabled'
    end
  end

private

  def most_active_records(model, action_foreign_key, limit, time_frame=nil)
    # Remove the third-party CTE gem and use the built-in CTE support in Rails 7.1
    raise if Rails.gem_version.to_s >= '7.1'

    cte = Action.select("#{action_foreign_key} AS join_id", 'COUNT(id) AS rank').group(action_foreign_key)
    cte = cte.where('created_at > ?', time_frame) if time_frame

    return model.with(actions: cte)
        .select("#{model.table_name}.*", 'actions.rank')
        .joins("INNER JOIN actions ON actions.join_id = #{model.table_name}.id")
        .order('actions.rank DESC')
        .limit(limit)
  end
end
