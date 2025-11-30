# frozen_string_literal: true

Rails.application.routes.draw do
  resources :examples
  resources :articles
  resources :products, only: %i[index show]
end
