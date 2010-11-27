module VCS
  class Git < Base
    NAME = "Git"

    def initialize(dir, branch)
      super(dir, branch)
    end

    def head_info
      info = {}
      command = "git log --max-count=1 --format=\"%H%n%an%n%ae%n%ad%n%s\" #{self.branch}"
      begin
        output = Runner.execute(self.dir, command)
      rescue Runner::Error => e
        raise VCS::Error.new("Couldn't access repository log")
      end
      commit_info = output.stdout.split("\n")
      info[:commit] = commit_info.shift
      info[:author] = commit_info.shift
      info[:email] = commit_info.shift
      info[:committed_at] = Time.parse(commit_info.shift)
      info[:commit_message] = commit_info.join("\n")
      [info, command]
    end

    def clone(where_to)
      command = "git clone --branch #{self.branch} #{self.dir} #{where_to}"
      Runner.execute(Dir.pwd, command)
    end
  end
end
