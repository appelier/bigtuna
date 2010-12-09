ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "blueprints"

DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
    FileUtils.rm_rf(File.join(Rails.root.to_s, "builds"))
  end

  def assert_invalid(klass, field, &block)
    object = klass.make
    assert object.valid?, "Basic object is not valid: check blueprints for %p" % [klass]
    yield object
    assert ! object.save, "Object is valid, but it's not supposed to be"
    assert ! object.errors[field].empty?, "No errors on field %p" % [field]
  end

  def with_hook_enabled(hook, &blk)
    BigTuna.hooks << hook
    blk.call
  ensure
    BigTuna.hooks.pop
  end

  def project_with_steps(project_attrs, *steps)
    project = Project.make(project_attrs)
    steps.each do |step_list|
      StepList.make(:project => project, :steps => step_list)
    end
    project
  end

  def run_delayed_jobs
    ran_jobs = []
    while Delayed::Job.count != 0
      Delayed::Job.all.each do |job|
        job.invoke_job
        job.destroy
        ran_jobs << job
      end
    end
    ran_jobs
  end
end
