#XMPP notifications
#We subclass ActionMailer
module BigTuna
  class Hooks::Xmpp
    NAME = "xmpp"
    
    # def self.build_passed(build, config)
    # end

    
    def self.build_fixed(build, config)
      Sender.delay.build_fixed(build,config) unless config["recipients"].split(",").empty?
    end

    def self.build_still_fails(build, config)
      Sender.delay.build_still_fails(build,config) unless config["recipients"].split(",").empty?
    end

    # def self.build_finished(build, config)
    # end

    def self.build_failed(build, config)
      Sender.delay.build_failed(build,config) unless config["recipients"].split(",").empty?
    end
    
    class Sender < ActionMailer::Base
      self.append_view_path("extras/big_tuna/hooks")
      
      def send_im(config,msg)
        recipients = config["recipients"].split(",")
        if recipients.size > 0          
          im = Jabber::Simple.new(config["sender_full_jid"], config["sender_password"])           
          recipients.each {|r| im.deliver(r, msg)}
        end
      end
         
      def build_failed(build, config)
        @build = build
        @project = @build.project
  
        send_im(
          config,           
          mail.body = render_to_string(
            "xmpp/build_failed", 
            :locals => {:build => @build, :project => @project}
          )
        )      
      end

      def build_still_fails(build, config)
        @build = build
        @project = @build.project
          
        send_im(
          config,           
          mail.body = render_to_string(
            "xmpp/build_still_fails", 
            :locals => {:build => @build, :project => @project}
          )
        )     
      end

      def build_fixed(build, config)
        @build = build
        @project = @build.project
          
        send_im(
          config,           
          mail.body = render_to_string(
            "xmpp/build_fixed", 
            :locals => {:build => @build, :project => @project}
          )
        )     
      end
    end    
  end
end
