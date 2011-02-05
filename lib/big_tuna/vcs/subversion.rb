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
      command = "svn log -l 1"
      begin
        output = BigTuna::Runner.execute(source, command)
      rescue BigTuna::Runner::Error => e
        raise BigTuna::VCS::Error.new("Couldn't access repository log")
      end
      log = output.stdout[1].match(/(\S+) \| (\S+) \| (.+) \|/)
      info[:commit] = log[1]
      info[:author] = log[2]
      email = begin
        YAML.load(File.read('config/email_addresses.yml'))[log[2]]
      rescue
        nil
      end
      info[:email] = email
      info[:committed_at] = Time.parse(log[3])
      info[:commit_message] = output.stdout[3..-2]
      [info, command]
    end

    def clone(where_to)
      command = "svn checkout #{source} #{where_to}"
      BigTuna::Runner.execute(Dir.pwd, command)
    end
  end
end
