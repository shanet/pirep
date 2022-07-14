Rails.application.routes.draw do
  root 'maps#index'

  resources :maps

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
