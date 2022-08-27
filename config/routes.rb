Rails.application.routes.draw do
  root 'map#index'
  get :map, to: 'map#index'

  devise_for :user, class_name: 'Users::User', controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
  }

  devise_scope :user do
    get 'user', to: 'users/registrations#show'
  end

  namespace :manage do
    root to: 'dashboard#index'
    resources :airports
    resources :users
  end

  resources :airports do
    get 'search(/:query)', action: :search, as: :search, on: :collection
  end

  resources :tags, only: :destroy

  resources :comments, only: :create do
    member do
      patch 'helpful', action: :helpful, as: :helpful
      patch 'flag', action: :flag_outdated, as: :flag_outdated
      patch 'undo_outdated', action: :undo_outdated, as: :undo_outdated
    end
  end
end
