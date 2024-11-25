class LeaderboardController < ApplicationController
  LEADERBOARD_LENGTH = 25 # users

  def index
    authorize :leaderboard
    @users = policy_scope(Users::User.where('points > 0').order(points: :desc).limit(LEADERBOARD_LENGTH), policy_scope_class: LeaderboardPolicy::Scope)
  end
end
