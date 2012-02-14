class ApplicationController < ActionController::Base
  self.append_view_path("lib/big_tuna/hooks")
  protect_from_forgery

  before_filter :gapps_required, :if => proc{ BigTuna.google_apps_domain }
  helper_method :gapps?

  def gapps_required
    redirect_to '/auth/gapps' unless gapps?
  end

  private

  def gapps?
    session[:gapps_user] = "marcin.stecki@netguru.pl"
    session[:gapps_user].present?
  end

end
