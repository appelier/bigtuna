module BigTuna
  class Hooks::Notifo < Hooks::Base
    NAME = "notifo"

    def build_fixed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(project.name, config, "Build '#{build.display_name}' in '#{project.name}' fixed", build_url(build)))
    end

    def build_still_fails(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(project.name, config, "Build '#{build.display_name}' in '#{project.name}' still fails", build_url(build)))
    end

    def build_failed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(project.name, config, "Build '#{build.display_name}' in '#{project.name}' failed", build_url(build)))
    end

    class Job
      def initialize(project_name, config, message, build_url)
        @project_name = project_name
        @config       = config
        @message      = message
        @build_url    = build_url
      end

      def perform
        recipients = @config["recipients"].to_s.split(",")
        if recipients.size > 0
          notifo = Notifo.new(@config["user"], @config["key"])
          recipients.each do |recipient|
            recipient.strip!
            notifo.subscribe_user(recipient)
            notifo.post(recipient, @message, @project_name, @build_url)
          end
        end
      end
    end
  end
end
