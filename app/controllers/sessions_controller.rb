class SessionsController < ApplicationController

  def authenticate_gapps
    auth_hash = request.env['omniauth.auth']

    session[:gapps_user] = auth_hash['user_info'].try(:[], 'email')

    if session[:gapps_user]
      redirect_to '/'
    else
      render :text => '401 Unauthorized', :status => 401
    end
  end

end
