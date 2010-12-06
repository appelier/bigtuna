ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "test/blueprints"

DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def assert_invalid(klass, field, &block)
    object = klass.make
    assert object.valid?, "Basic object is not valid: check blueprints for %p" % [klass]
    yield object
    assert ! object.save, "Object is valid, but it's not supposed to be"
    assert ! object.errors[field].empty?, "No errors on field %p" % [field]
  end

  def with_hook_enabled(hook, &blk)
    old_hooks = BigTuna::HOOKS.clone
    Kernel.silence_stream(STDERR) do
      BigTuna.const_set("HOOKS", old_hooks + [hook])
    end
    blk.call
  ensure
    Kernel.silence_stream(STDERR) do
      BigTuna.const_set("HOOKS", old_hooks)
    end
  end
end
