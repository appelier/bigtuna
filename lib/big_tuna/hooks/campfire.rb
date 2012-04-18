module BigTuna
  class Hooks::Campfire < Hooks::Base
    NAME = 'campfire'

    def build_fixed(build, config)
      enqueue(config, full_msg(build, 'fixed'))
    end

    def build_still_fails(build, config)
      enqueue(config, full_msg(build, 'still fails'), "vuvuzela")
    end

    def build_failed(build, config)
      enqueue(config, full_msg(build, 'failed'), "vuvuzela")
    end

    class Job
      def initialize(config, message, sound)
        @config = config
        @message = message
        @sound = sound
      end

      def perform
        if @config['subdomain'] and @config['token'] and @config['room']
          use_ssl = (@config['use_ssl'].to_i == 1)

          campfire = Tinder::Campfire.new(@config['subdomain'],
                                          :token => @config['token'],
                                          :ssl => use_ssl)
          room = campfire.find_room_by_name(@config['room'])
          room.speak(@message)
          room.play(@sound) if @sound
        end
      end
    end

  private
    def enqueue(config, message, sound = nil)
      Delayed::Job.enqueue(Job.new(config, message, sound))
    end

    def full_msg(build, status)
      "#{build.project.name} build ##{build.build_no} #{status} @ #{build.commit[0..6]} by #{build.author} (#{build_url(build)})"
    end
  end
end
