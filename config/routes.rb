Rails.application.routes.draw do
  root 'maps#index'

  resources :maps do
  end

  resources :airports do
  end

  resources :tags, only: :create

  namespace :airports do
    get 'search(/:query)', action: :search, as: :search
  end
end
