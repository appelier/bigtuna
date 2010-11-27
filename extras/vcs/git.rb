module VCS
  class Git < Base
    NAME = "Git"

    def initialize(dir)
      super
    end

    def head_info
      info = {}
      command = "cd #{self.dir}; git log --max-count=1 --format=\"%H%n%an%n%ae%n%ad%n%s\""
      commit_info = `#{command}`.split("\n")
      info[:commit] = commit_info.shift
      info[:author] = commit_info.shift
      info[:email] = commit_info.shift
      info[:committed_at] = Time.parse(commit_info.shift)
      info[:commit_message] = commit_info.join("\n")
      [info, command]
    end

    def clone(where_to)
      command = "git clone #{self.dir} #{where_to}"
      out = `#{command}`
      [out, command]
    end

    def valid?
      out = `cd #{self.dir} 2>&1 && git ls-files 2>&1; echo $?`
      out.split[-1].strip.to_i == 0
    end
  end
end
