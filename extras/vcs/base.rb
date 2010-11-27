module VCS
  class Base
    attr_reader :dir, :branch

    def initialize(dir, branch)
      @dir = dir
      @branch = branch
    end
  end
end
