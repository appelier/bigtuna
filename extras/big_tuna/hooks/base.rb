module BigTuna::Hooks
  class Base
    include Rails.application.routes.url_helpers

    def default_url_options
      ActionMailer::Base.default_url_options
    end

    def build_passed(build, config)
    end

    def build_fixed(build, config)
    end

    def build_still_fails(build, config)
    end

    def build_finished(build, config)
    end

    def build_failed(build, config)
    end
  end
end
