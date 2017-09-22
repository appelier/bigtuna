require "integration_test_helper"

class GoogleAppsAuth < ActionController::IntegrationTest

  test "with google apps domain in config accesing root" do
    with_config(:google_apps_domain, "somedomain.com") do
      get "/"
      assert_redirected_to "http://www.example.com/auth/gapps"
    end
  end

end
