class ApplicationController < ActionController::Base
  self.append_view_path("lib/big_tuna/hooks")
  protect_from_forgery

  before_filter :authenticate

  private

  def authenticate
    if !BigTuna.auth_user.blank? and !BigTuna.auth_password.blank?
      authenticate_or_request_with_http_basic do |user_name, password|
        user_name == BitTuna.auth_user && password == BigTuna.auth_password
      end
    end
  end


end
