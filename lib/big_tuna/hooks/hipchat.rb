module BigTuna
  class Hooks::Hipchat < Hooks::Base
    NAME = 'hipchat'

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
        response = send_request
        data = response.body
        { :message => @message, :room => @config['room_id'], :response => response, :data => data }
      end

      def send_request
        request = create_request
        Net::HTTP.start(uri.host, uri.port, http_options) do |http|
          http.request request
        end
      end

      def create_request
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data(payload)
        req
      end

      def uri
        @uri ||= URI("https://api.hipchat.com/v1/rooms/message")
      end

      def http_options
        {
          :use_ssl => true,
          :verify_mode => OpenSSL::SSL::VERIFY_NONE
        }
      end

      def payload
        {
          :format     => 'json',
          :auth_token => @config['token'],
          :room_id    => @config['room_id'],
          :from       => 'Big Tuna',
          :message    => @message,
        }
      end

    end

    private

      def enqueue(config, message)
        Delayed::Job.enqueue(Job.new(config, message))
      end

      def full_msg(build, status)
        "Build #{status} in #{build.project.name}: #{commit_info(build)}"
      end

      def commit_info(build)
        source = build.project.vcs_source
        if source.match('github.com')
          github_commit_link(build)
        else
          "#{build.commit_message} (#{build.commit[0..6]} by #{build.author})"
        end
      end

      def github_commit_link(build)
        source = build.project.vcs_source
        prefix = source.sub('git@github.com:', 'https://github.com/').sub(/\.git$/, '')
        link = "#{prefix}/commit/#{build.commit}"
        "<a href=\"#{build_url(build)}\">#{build.commit_message}</a> (commit <a href=\"#{link}\">#{build.commit[0..6]} by #{build.author}</a>)"
      end

      def build_url(build)
        url_host = BigTuna.config[:url_host]
        "http://#{url_host}/builds/#{build.id}"
      end

  end
end

