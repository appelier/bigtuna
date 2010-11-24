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
      assert_equal status_code, page.status_code
    end
  end
end
