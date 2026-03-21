Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "forecast", to: "weather#forecast"
      get "current",  to: "weather#current"
      get "health",   to: "health#show"
    end
  end

  # Catch-all: return JSON 404 for unknown routes instead of Rails HTML error page
  match "*path", to: "application#not_found", via: :all
end
