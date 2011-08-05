# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if ENV['BIGTUNA_HTTP_AUTH_USERNAME'] && ENV['BIGTUNA_HTTP_AUTH_PASSWORD']
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == [ENV['BIGTUNA_HTTP_AUTH_USERNAME'], ENV['BIGTUNA_HTTP_AUTH_PASSWORD']]
  end
end

run BigTuna::Application
