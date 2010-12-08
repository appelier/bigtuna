class Hook < ActiveRecord::Base
  belongs_to :project
  serialize :configuration, Hash

  def backend
    @backend ||= BigTuna::HOOKS.find { |e| e::NAME == hook_name }.new
  end

  def configuration
    super || {}
  end

  def build_passed(build)
    invoke_with_log(build) do
      self.backend.build_passed(build, self.configuration)
    end
  end

  def build_still_passes(build)
    invoke_with_log(build) do
      self.backend.build_still_passes(build, self.configuration)
    end
  end

  def build_fixed(build)
    invoke_with_log(build) do
      self.backend.build_fixed(build, self.configuration)
    end
  end

  def build_still_fails(build)
    invoke_with_log(build) do
      self.backend.build_still_fails(build, self.configuration)
    end
  end

  def build_finished(build)
    invoke_with_log(build) do
      self.backend.build_finished(build, self.configuration)
    end
  end

  def build_failed(build)
    invoke_with_log(build) do
      self.backend.build_failed(build, self.configuration)
    end
  end

  private
  def invoke_with_log(build, &blk)
    begin
      blk.call
    rescue Exception => e
      BigTuna.logger.error("Exception while running #{hook_name} hook")
      BigTuna.logger.error(e.message)
      BigTuna.logger.error(e.backtrace.join("\n"))
      build.status = Build::STATUS_HOOK_ERROR
      build.save!
    end
  end
end
