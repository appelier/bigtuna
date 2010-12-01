require "test_helper"
require "capybara/rails"

module ActionController
  class IntegrationTest
    include Capybara

    def setup
      super
      Capybara.reset_sessions!
    end

    def assert_status_code(status_code)
      begin
        status = page.status_code
        assert_equal status_code, page.status_code
      rescue Rack::Test::Error => e
        assert_equal status_code, response.status
      end
    end
  end
end
