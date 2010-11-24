BigTuna::Application.routes.draw do
  resources :projects do
    member { get "build" }
  end
  resources :builds
  root :to => "projects#index"
end
