class Hook < ActiveRecord::Base
  belongs_to :project
  serialize :configuration, Hash
  serialize :hooks_enabled, Array
  AVAILABLE_HOOKS = ["build_passed", "build_fixed", "build_still_fails", "build_still_passes", "build_finished", "build_failed"]

  before_create :enable_all_hooks

  def backend
    @backend ||= BigTuna.hooks.find { |e| e::NAME == hook_name }.new
  end

  def configuration
    super || {}
  end

  def build_passed(build)
    invoke_with_log(build) do
      self.backend.build_passed(build, self.configuration) if hook_available?("build_passed")
    end
  end

  def build_still_passes(build)
    invoke_with_log(build) do
      self.backend.build_still_passes(build, self.configuration) if hook_available?("build_still_passes")
    end
  end

  def build_fixed(build)
    invoke_with_log(build) do
      self.backend.build_fixed(build, self.configuration) if hook_available?("build_fixed")
    end
  end

  def build_still_fails(build)
    invoke_with_log(build) do
      self.backend.build_still_fails(build, self.configuration) if hook_available?("build_still_fails")
    end
  end

  def build_finished(build)
    invoke_with_log(build) do
      self.backend.build_finished(build, self.configuration) if hook_available?("build_finished")
    end
  end

  def build_failed(build)
    invoke_with_log(build) do
      self.backend.build_failed(build, self.configuration) if hook_available?("build_failed")
    end
  end

  def hook_implemented?(name)
    self.backend.respond_to?(name.to_sym)
  end

  def hook_enabled?(name)
    hooks_enabled.include?(name)
  end

  def hook_available?(name)
     hook_implemented?(name) and hook_enabled?(name)
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

  def enable_all_hooks
    self.hooks_enabled = AVAILABLE_HOOKS.dup
  end
end
