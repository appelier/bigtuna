module BigTuna
  class Hooks::Xmpp < Hooks::Base
    NAME = "xmpp"

    def build_fixed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "Build '#{build.display_name}' in '#{project.name}' fixed (#{build_url(build)})"))
    end

    def build_still_fails(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "Build '#{build.display_name}' in '#{project.name}' still fails (#{build_url(build)})"))
    end

    def build_failed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "Build '#{build.display_name}' in '#{project.name}' failed (#{build_url(build)})"))
    end

    class Job
      def initialize(config, message)
        @config = config
        @message = message
      end

      def perform
        recipients = @config["recipients"].to_s.split(",")
        if recipients.size > 0
          im = Jabber::Simple.new(@config["sender_full_jid"], @config["sender_password"])
          recipients.each { |r| im.deliver(r.strip, @message) }
        end
      end
    end
  end
end
