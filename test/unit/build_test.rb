require 'test_helper'

class BuildTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir koss; cd koss; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/koss")
    super
  end

  test "invalid build is marked as invalid and failed count gets updated" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/koss",
      :max_builds => 1,
    }, "ls /not/existing")
    assert_equal 0, project.failed_builds
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_FAILED, build.status
    project.reload
    assert_equal 1, project.failed_builds
  end

  test "special variable %build_dir% is available in steps" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/koss",
      :max_builds => 1,
    }, "ls -al file\nls %build_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert build.parts[0].output[1].stdout.include?("file")
  end

  test "special variable %project_dir% is available in steps" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/koss",
      :max_builds => 1,
    }, "ls -al file\nls %project_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert build.parts[0].output[1].stdout.include?(build.build_dir.split("/")[-1]) # build folder
  end

  test "if step produces white output then it should be set to nil" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/koss",
      :max_builds => 1,
    }, "cd %project_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert_equal [], build.parts[0].output[-1].stdout
  end

  test "build #to_param includes build display name and project name" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/koss",
      :vcs_type => "git",
      :max_builds => 2,
    }, "ls .")
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert build.to_param =~ /^#{build.id}/
    assert build.to_param.include?(project.name.to_url)
    assert build.to_param.include?(build.display_name.to_url)
  end
end
