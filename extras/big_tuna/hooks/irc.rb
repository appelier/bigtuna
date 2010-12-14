module BigTuna
  class Hooks::Irc < Hooks::Base
    NAME = "irc"

    def build_still_passes(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' STILL PASSES (#{build_url(build)})"))
    end

    def build_fixed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' FIXED (#{build_url(build)})"))
    end

    def build_still_fails(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' STILL FAILS (#{build_url(build)})"))
    end

    def build_failed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' FAILED (#{build_url(build)})"))
    end

    class Job
      def initialize(config, message)
        @config = config
        @message = message
      end

      def perform
        uri = "irc://#{@config[:user_name]}"

        #Password protected channels not currently supported by shout-bot
        #uri += ":#{@config[:room_password]}" if @config[:room_password].present?

        uri += "@#{@config[:server]}:#{@config[:port].present? ? @config[:port] : '6667'}"
        uri += "/##{@config[:room].to_s.gsub("#","") }"
        ShoutBot.shout(uri) { |channel| channel.say @message }
      end
    end
  end
end
