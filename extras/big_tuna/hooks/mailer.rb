module BigTuna
  class Hooks::Mailer
    NAME = "mailer"

    # def self.build_passed(build)
    # end

    def self.build_fixed(build)
      Sender.delay.build_fixed(build)
    end

    def self.build_still_fails(build)
      Sender.delay.build_still_fails(build)
    end

    # def self.build_finished(build)
    # end

    def self.build_failed(build)
      Sender.delay.build_failed(build)
    end

    class Sender < ActionMailer::Base
      self.append_view_path("extras/big_tuna/hooks/mailer")
      default :from => "info@ci.appelier.com"

      def build_failed(build)
        @build = build
        @project = @build.project
        recipients = @project.recipients
        mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' failed") do |format|
          format.text { render "/build_failed" }
        end
      end

      def build_still_fails(build)
        @build = build
        @project = @build.project
        recipients = @project.recipients
        mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' still fails") do |format|
          format.text { render "/build_still_fails" }
        end
      end

      def build_fixed(build)
        @build = build
        @project = @build.project
        recipients = @project.recipients
        mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' fixed") do |format|
          format.text { render "/build_fixed" }
        end
      end
    end
  end
end
