class ApplicationController < ActionController::Base
  self.append_view_path("lib/big_tuna/hooks")
  protect_from_forgery

  before_filter :authenticate

  private

  def authenticate
<<<<<<< Updated upstream
    if !BigTuna.auth_user.blank? and !BigTuna.auth_password.blank?
=======

    #logger.info "User/password: #{BigTuna.auth_user} #{BigTuna.auth_password}"

    if !BigTuna.auth_user.blank? && !BigTuna.auth_password.blank?
>>>>>>> Stashed changes
      authenticate_or_request_with_http_basic do |user_name, password|
        user_name == BigTuna.auth_user && password == BigTuna.auth_password
      end
    end
  end


end
