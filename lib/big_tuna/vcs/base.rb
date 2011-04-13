module BigTuna::VCS
  class Base
    attr_reader :source, :branch

    def initialize(source, branch)
      @source = source
      @branch = branch
    end

    def self.supported?
      raise ArgumentError.new("Implement ::supported? method")
    end

    def self.inherited(klass)
      BigTuna.vcses << klass
      BigTuna.logger.info("Registered VCS: %s" % [klass])
    end
    
    def support_incremental_build?
      respond_to?(:update)
    end
  end
end
