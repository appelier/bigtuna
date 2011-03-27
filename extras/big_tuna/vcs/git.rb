module BigTuna::VCS
  class Git < Base
    NAME = "Git"
    VALUE = "git"

    def self.supported?
      return @_supported unless @_supported.nil?
      begin
        @_supported = BigTuna::Runner.execute(Dir.pwd, "git --version").ok?
      rescue BigTuna::Runner::Error => e
        @_supported = false
      end
      @_supported &&= self.version_at_least?("1.5.1")
    end

    def self.version_at_least?(version)
      if @_version.nil?
        output = BigTuna::Runner.execute(Dir.pwd, "git --version").stdout.first
        @_version = output.match(/\d+\.\d+\.\d+/)[0].split(".").map { |e| e.to_i }
      end
      parts = version.split(".").map { |e| e.to_i }
      parts.each_with_index do |part, index|
        if part > @_version[index]
          return false
        elsif part < @_version[index]
          return true
        end
      end
      return true
    end

    def head_info
      info = {}
      command = "git log --max-count=1 --pretty=format:%H%n%an%n%ae%n%ad%n%s #{self.branch}"
      begin
        output = BigTuna::Runner.execute(self.source, command)
      rescue BigTuna::Runner::Error => e
        raise BigTuna::VCS::Error.new("Couldn't access repository log")
      end
      head_hash = output.stdout
      info[:commit] = head_hash.shift
      info[:author] = head_hash.shift
      info[:email] = head_hash.shift
      info[:committed_at] = Time.parse(head_hash.shift)
      info[:commit_message] = head_hash.join("\n")
      [info, command]
    end

    def clone(where_to)
      if self.class.version_at_least?("1.6.5")
        command = "git clone --branch #{self.branch} --depth 1 #{self.source} #{where_to}"
      else
        command = "mkdir -p #{where_to} && cd #{where_to} && git init && git pull #{self.source} #{self.branch} && git branch -M master #{self.branch}"
      end
      BigTuna::Runner.execute(Dir.pwd, command)
    end
    
    def update(where_to)
      command = 'git clean -fd && git pull'
      BigTuna::Runner.execute(where_to, command)
    end
  end
end
