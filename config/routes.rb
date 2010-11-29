BigTuna::Application.routes.draw do
  resources :projects do
    member { get "build"; get "remove"; get "arrange" }
    match "/hooks/:name/configure", :to => "hooks#configure", :as => "config_hook"
  end
  resources :builds
  match "/hooks/build/:hook_name", :to => "hooks#autobuild"
  root :to => "projects#index"
end
