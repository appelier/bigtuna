module BigTuna::VCS
  class Git < Base
    NAME = "Git"
    VALUE = "git"

    def self.supported?
      @_supported ||= BigTuna::Runner.execute(Dir.pwd, "git --version").ok?
    end

    def head_info
      info = {}
      command = "git log --max-count=1 --format=\"%H%n%an%n%ae%n%ad%n%s\" #{self.branch}"
      begin
        output = BigTuna::Runner.execute(self.source, command)
      rescue BigTuna::Runner::Error => e
        raise VCS::Error.new("Couldn't access repository log")
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
      command = "git clone --branch #{self.branch} --depth 1 #{self.source} #{where_to}"
      BigTuna::Runner.execute(Dir.pwd, command)
    end
  end
end
