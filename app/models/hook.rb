class Hook < ActiveRecord::Base
  belongs_to :project
  serialize :configuration, Hash

  def backend
    @backend ||= BigTuna::HOOKS.find { |e| e::NAME == hook_name }
  end

  def configuration
    super || {}
  end

  def build_passed(build)
    self.backend.build_passed(build, self.configuration) if self.backend.respond_to?(:build_passed)
  end

  def build_fixed(build)
    self.backend.build_fixed(build, self.configuration) if self.backend.respond_to?(:build_fixed)
  end

  def build_still_fails(build)
    self.backend.build_still_fails(build, self.configuration) if self.backend.respond_to?(:build_still_fails)
  end

  def build_finished(build)
    self.backend.build_finished(build, self.configuration) if self.backend.respond_to?(:build_finished)
  end

  def build_failed(build)
    self.backend.build_failed(build, self.configuration) if self.backend.respond_to?(:build_failed)
  end
end
