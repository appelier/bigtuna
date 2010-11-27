module VCS
  class Base
    attr_reader :dir
    def initialize(dir)
      @dir = dir
      raise Error.new("Repository not found under '%s'" % [dir]) unless self.valid?
    end
  end
end
