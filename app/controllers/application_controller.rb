class ApplicationController < ActionController::Base
  self.append_view_path("lib/big_tuna/hooks")
  protect_from_forgery
end
