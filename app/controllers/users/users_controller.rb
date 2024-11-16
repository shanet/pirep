class Users::UsersController < ApplicationController
  before_action :set_user, only: [:show, :activity]

  def show
  end

  def activity
    @actions = policy_scope(Action.where(user: @user).order(created_at: :desc).page(params[:page]))
  end

private

  def set_user
    @user = Users::User.find(params[:id])
    authorize @user, policy_class: Users::UsersPolicy
  end
end
