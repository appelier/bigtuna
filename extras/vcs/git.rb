module VCS
  class Git
    NAME = "Git"

    def initialize(dir)
      raise ArgumentError.new("Repository not found under %p" % [dir]) unless File.directory?(dir)
      @dir = dir
    end

    def head_info
      info = {}
      command = "cd #{@dir}; git log --max-count=1 --format=\"%H%n%an%n%ae%n%ad%n%s\""
      commit_info = `#{command}`.split("\n")
      info[:commit] = commit_info.shift
      info[:author] = commit_info.shift
      info[:email] = commit_info.shift
      info[:committed_at] = Time.parse(commit_info.shift)
      info[:commit_message] = commit_info.join("\n")
      [info, command]
    end

    def clone(where_to)
      command = "git clone #{@dir} #{where_to}"
      out = `#{command}`
      [out, command]
    end
  end
end
