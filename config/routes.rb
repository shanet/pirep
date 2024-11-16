Rails.application.routes.draw do
  root 'map#index'
  get :map, to: 'map#index'

  get :about, to: 'meta#about'
  get :health, to: 'meta#health'
  get :sitemap, to: 'meta#sitemap'

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
    patch 'user/verify', to: 'users/registrations#verify', as: :verify_user
  end

  # Enable the GoodJob dashboard
  authenticate :user, ->(user) {user.admin?} do
    mount GoodJob::Engine => 'good_job'
  end

  namespace :manage do
    root to: 'dashboard#index'
    get 'activity', to: 'dashboard#activity', as: :activity
    patch 'update_read_only', to: 'dashboard#update_read_only', as: :update_read_only

    resources :attachments, only: [:index, :destroy]
    resources :comments
    resources :webcams, only: :destroy
    resources :versions, only: :update

    resources :airports do
      get 'search', action: :search, as: :search, on: :collection

      member do
        get 'analytics', as: :analytics
        delete 'attachment/:type/:attachment_id', action: :destroy_attachment, as: :destroy_attachment
      end
    end

    resources :users do
      get 'search', action: :search, as: :search, on: :collection

      member do
        get 'activity', to: 'users#activity', as: :activity
        get 'analytics', to: 'users#analytics', as: :analytics
      end
    end
  end

  resources :airports do
    get 'search', action: :search, as: :search, on: :collection
    get 'basic_search', action: :basic_search, as: :basic_search, on: :collection
    get 'advanced_search', action: :advanced_search, as: :advanced_search, on: :collection

    member do
      get 'history', as: :history
      get 'preview/:version_id', action: :preview, as: :preview
      get 'annotations', as: :annotations
      get 'uncached_photo_gallery', as: :uncached_photo_gallery
    end
  end

  resources :comments, only: [:create, :destroy] do
    member do
      patch 'helpful', action: :helpful, as: :helpful
      patch 'flag', action: :flag_outdated, as: :flag_outdated
      patch 'undo_outdated', action: :undo_outdated, as: :undo_outdated
    end
  end

  resources :events, only: [:create, :edit, :update, :show, :destroy]
  resources :tags, only: :destroy

  resources :users, only: [], controller: 'users/users' do
    member do
      get 'show', as: :users_show
      get 'activity', as: :users_activity
    end
  end

  resources :versions, only: [] do
    member do
      patch 'revert', action: :revert, as: :revert
    end
  end

  resources :webcams, only: [:create, :destroy]
end
