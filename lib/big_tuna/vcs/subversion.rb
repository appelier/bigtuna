module BigTuna::VCS
  class Subversion < Base
    NAME = "Subversion"
    VALUE = "svn"

    def self.supported?
      return @_supported unless @_supported.nil?
      begin
        @_supported = BigTuna::Runner.execute(Dir.pwd, "svn --version").ok?
      rescue BigTuna::Runner::Error => e
        @_supported = false
      end
      @_supported
    end

    def head_info
      info = {}
      command = "svn log -l 1 --xml"
      begin
        output = BigTuna::Runner.execute(source, command)
      rescue BigTuna::Runner::Error => e
        raise BigTuna::VCS::Error.new("Couldn't access repository log")
      end
      log = output.stdout.join.match(/revision="(\d+)"><author>(\S+)<\/author><date>(\S+)<\/date><msg>(.*)<\/msg>/)
      info[:commit] = "r#{log[1]}"
      info[:author] = log[2]
      info[:email] = log[2] # svn does not have email addresses associated
      info[:committed_at] = Time.parse(log[3])
      info[:commit_message] = log[4]
      [info, command]
    end

    def clone(where_to)
      command = "svn checkout #{source} #{where_to}"
      BigTuna::Runner.execute(Dir.pwd, command)
    end

    def update(where_to)
      BigTuna::Runner.execute(where_to, 'svn st --no-ignore').stdout.each do |file|
        FileUtils.rm_rf(File.join(where_to, file[1..-1].strip)) if %w(? I).include?(file[0..0])
      end
      BigTuna::Runner.execute(where_to, 'svn update')
    end
  end
end
