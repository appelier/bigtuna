module BigTuna
  class Hooks::Mailer
    NAME = "mailer"

    # def self.build_passed(build, config)
    # end

    def self.build_fixed(build, config)
      recipients = config["recipients"]
      Sender.delay.build_fixed(build, recipients) unless recipients.blank?
    end

    def self.build_still_fails(build, config)
      recipients = config["recipients"]
      Sender.delay.build_still_fails(build, recipients) unless recipients.blank?
    end

    # def self.build_finished(build, config)
    # end

    def self.build_failed(build, config)
      recipients = config["recipients"]
      Sender.delay.build_failed(build, recipients) unless recipients.blank?
    end

    class Sender < ActionMailer::Base
      self.append_view_path("extras/big_tuna/hooks")
      default :from => "info@ci.appelier.com"

      def build_failed(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' failed") do |format|
          format.text { render "mailer/build_failed" }
        end
      end

      def build_still_fails(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' still fails") do |format|
          format.text { render "mailer/build_still_fails" }
        end
      end

      def build_fixed(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' fixed") do |format|
          format.text { render "mailer/build_fixed" }
        end
      end
    end
  end
end
