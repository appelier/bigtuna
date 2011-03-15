require 'test_helper'

class SharedVariableTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir var_repo; cd var_repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/var_repo")
    super
  end

  test "shared variables actually work" do
    project = project_with_steps({
      :name => "Project",
      :vcs_source => "test/files/var_repo",
      :max_builds => 1,
    }, "%sharedvar13%")
    step_list = project.step_lists[0]
    v = step_list.shared_variables.create!(:name => "sharedvar13", :value => "echo %build_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    parts = build.parts
    assert_equal 1, parts.size
    part = parts[0]
    out = part.output[0]
    assert_equal "echo #{build.build_dir}", out.command
    assert_equal build.build_dir, out.stdout[0]
  end
end
