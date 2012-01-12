ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/test_unit'
require "blueprints"

DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
    FileUtils.rm_rf(File.join(Rails.root.to_s, BigTuna.build_dir))
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

  def with_config(key, new_value, &blk)
    old_value = BigTuna.config[key]
    BigTuna.config[key] = new_value
    blk.call
  ensure
    BigTuna.config[key] = old_value
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

  def create_test_repo
    command = <<-CMD.gsub("\n", "; ")
      mkdir -p test/files/repo
      cd test/files/repo
      git init
      git config user.name git
      git config user.email git@example.com
      echo "my file" > file
      git add file
      git commit -m "my file added"
    CMD
    `#{command}`
  end

  def destroy_test_repo
    FileUtils.rm_rf 'test/files/repo'
    FileUtils.rm_rf 'test/files/build'
  end

  module WithTestRepo
    def setup
      super
      create_test_repo
    end

    def teardown
      destroy_test_repo
      super
    end
  end
end
