BigTuna::Application.routes.draw do
  if BigTuna.read_only?

    resources :projects, :only => [:index, :show] do
      member { get "feed" }
    end
    resources :builds, :only => [:show]

  else

    resources :projects do
      member { get "build"; get "remove"; get "arrange"; get "feed" }
      match "/hooks/:name/configure", :to => "hooks#configure", :as => "config_hook"
    end
    resources :builds

  end

  match "/hooks/build/:hook_name", :to => "hooks#autobuild"
  match "/hooks/build/github/:secure", :to => "hooks#github"
  root :to => "projects#index"
end
