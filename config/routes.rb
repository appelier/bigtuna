BigTuna::Application.routes.draw do
  resources :projects do
    member { get "build" }
  end
  resources :builds
  match "/hooks/post_commit", :to => "hooks#post_commit"
  root :to => "projects#index"
end
