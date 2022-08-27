class Manage::UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = Users::User.order(:updated_at).page(params[:page])
    authorize @users, policy_class: Manage::UserPolicy
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to manage_user_path(@user), notice: 'User updated successfully'
    else
      redirect_to edit_manage_user_path(@user)
    end
  end

  def destroy
    if @user.destroy
      redirect_to manage_users_path, notice: 'User deleted successfully'
    else
      redirect_to manage_user_path(@user)
    end
  end

private

  def set_user
    @user = Users::User.find(params[:id])
    authorize @user, policy_class: Manage::UserPolicy
  end

  def user_params
    return params.require(:users_user).permit(:name, :email, :type)
  end
end
