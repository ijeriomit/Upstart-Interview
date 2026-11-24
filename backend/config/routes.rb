Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "csrf", to: "sessions#csrf"
    resource :session, only: [:create, :destroy]
    get "me", to: "users#show"
    resources :accounts, only: [:index, :show] do
      resources :transactions, only: [:create]
    end
  end
end
