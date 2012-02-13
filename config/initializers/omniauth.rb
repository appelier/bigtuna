Rails.application.config.middleware.use OmniAuth::Builder do

  provider :google_apps, :domain => BigTuna.google_apps_domain, :name =>
'gapps'
end if BigTuna.google_apps_domain
