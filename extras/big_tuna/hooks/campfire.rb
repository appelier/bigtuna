module BigTuna
  class Hooks::Campfire < Hooks::Base
    NAME = 'campfire'

    def build_fixed(build, config)
      enqueue(config, full_msg(build, 'fixed'))
    end

    def build_still_fails(build, config)
      enqueue(config, full_msg(build, 'still fails'))
    end

    def build_failed(build, config)
      enqueue(config, full_msg(build, 'failed'))
    end

    class Job
      def initialize(config, message)
        @config = config
        @message = message
      end

      def perform
        if @config['subdomain'] and @config['token'] and @config['room']
          use_ssl = (@config['use_ssl'].to_i == 1)

          campfire = Tinder::Campfire.new(@config['subdomain'],
                                          :token => @config['token'],
                                          :ssl => use_ssl)
          room = campfire.find_room_by_name(@config['room'])
          room.speak(@message)
        end
      end
    end

  private
    def enqueue(config, message)
      Delayed::Job.enqueue(Job.new(config, message))
    end

    def full_msg(build, status)
      "Build '#{build.display_name}' in '#{build.project.name}' #{status} (#{build_url(build)})"
    end
  end
end
