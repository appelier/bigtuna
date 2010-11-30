class ApplicationController < ActionController::Base
  self.append_view_path("extras/big_tuna/hooks")
  protect_from_forgery
end
