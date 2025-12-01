# frozen_string_literal: true

Rails.application.routes.draw do
  resources :examples
  resources :articles do
    resources :comments
  end
  resources :products
  resources :tasks do
    member do
      post :complete
    end
  end

  # ActionDSL test routes (with mock service)
  resources :action_dsl_products, only: %i[index show]

  # Pagination test routes
  resources :paginated_products

  # CSV export test routes
  resources :csv_exports, only: %i[index show]

  namespace :api do
    resources :users
  end
end
