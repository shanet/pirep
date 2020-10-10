Rails.application.routes.draw do
  root 'maps#index'

  resources :maps do
  end

  resources :airports do
  end
end
