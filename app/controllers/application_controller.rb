class ApplicationController < ActionController::Base
  self.append_view_path("lib/big_tuna/hooks")
  protect_from_forgery

  before_filter :gapps_required, :if => proc{ BigTuna.google_apps_domain }

  def gapps_required
    redirect_to '/auth/gapps' unless session[:gapps_user]
  end

end
