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
    get 'user/activity', to: 'users/registrations#activity', as: :activity_user
    patch 'user/timezone', to: 'users/registrations#update_timezone', as: :update_timezone_user
  end

  namespace :manage do
    root to: 'dashboard#index'
    get 'activity', to: 'dashboard#activity', as: :activity
    resources :comments

    resources :airports do
      get 'search', action: :search, as: :search, on: :collection

      member do
        patch 'version/:version_id', action: :update_version, as: :version
      end
    end

    resources :users do
      get 'search', action: :search, as: :search, on: :collection

      member do
        get 'activity', to: 'users#activity', as: :activity
      end
    end
  end

  resources :airports do
    get 'search', action: :search, as: :search, on: :collection

    member do
      get 'history', as: :history
      get 'preview/:version_id', action: :preview, as: :preview
      patch 'revert/:version_id', action: :revert, as: :revert
    end
  end

  resources :tags, only: :destroy do
    member do
      patch 'revert', action: :revert, as: :revert
    end
  end

  resources :comments, only: [:create, :destroy] do
    member do
      patch 'helpful', action: :helpful, as: :helpful
      patch 'flag', action: :flag_outdated, as: :flag_outdated
      patch 'undo_outdated', action: :undo_outdated, as: :undo_outdated
    end
  end
end
