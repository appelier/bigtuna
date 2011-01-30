module BigTuna
  class Hooks::Talker < Hooks::Base
    NAME = "talker"

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
      require 'net/http'
      require 'net/https'

      def initialize(config, message)
        @config = config
        @message = message
      end

      def perform
        path = "/rooms/#{@config[:room].to_s}/messages.json"
        payload = ActiveSupport::JSON.encode({ :message => @message })
        headers = {'Accept' => 'application/json', 
                   'Content-Type' => 'application/json',
                   'X-Talker-Token' => @config[:token]}

        http = Net::HTTP.new(@config[:subdomain], 443)
        http.use_ssl = (@config['use_ssl'].to_i == 1) 
        response, data = http.post(path, payload, headers)

        { :message => @message, :room => @config[:room], :response => response, :data => data }
      end
    end

    private
      def enqueue(config, message)
        Delayed::Job.enqueue(Job.new(config, message))
      end

      def full_msg(build, status)
        "Build '#{build.display_name}' in '#{build.project.name}' #{status}"
      end
  end
end
