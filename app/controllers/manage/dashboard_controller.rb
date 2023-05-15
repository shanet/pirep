class Manage::DashboardController < ApplicationController
  def index
    authorize :dashboard, policy_class: Manage::DashboardPolicy
    flash.now[:error] = 'Read only mode is enabled' if Rails.configuration.read_only.enabled?
  end

  def activity
    authorize :activity, policy_class: Manage::DashboardPolicy

    @limit = 10

    @read_airports = {
      all_time: most_active_records(Airport, Pageview, :record_id, @limit),
      month: most_active_records(Airport, Pageview, :record_id, @limit, 1.month.ago),
    }

    @edited_airports = {
      all_time: most_active_records(Airport, Action, :actionable_id, @limit),
      month: most_active_records(Airport, Action, :actionable_id, @limit, 1.month.ago),
    }

    @active_users = {
      all_time: most_active_records(Users::User, Action, :user_id, @limit),
      month: most_active_records(Users::User, Action, :user_id, @limit, 1.month.ago),
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

  def most_active_records(data_model, event_model, polymorphic_column, limit, time_frame=nil)
    # Remove the third-party CTE gem and use the built-in CTE support in Rails 7.1
    raise if Rails.gem_version.to_s >= '7.1'

    # Events model = The model where the events are stored (Action for user edit actions, Pageview for reads)
    # Data model = The model to aggregate data and generate a count for (airports, users, etc.)

    cte = event_model.select("#{polymorphic_column} AS join_id", 'COUNT(id) AS rank').group(polymorphic_column)
    cte = cte.where('created_at > ?', time_frame) if time_frame

    return data_model.with(cte: cte)
        .select("#{data_model.table_name}.*", 'cte.rank')
        .joins("INNER JOIN cte ON cte.join_id = #{data_model.table_name}.id")
        .order('cte.rank DESC')
        .limit(limit)
  end
end
