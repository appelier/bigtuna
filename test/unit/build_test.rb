require 'test_helper'

class BuildTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir koss; cd koss; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/koss")
    FileUtils.rm_rf("builds/koss")
    super
  end

  test "invalid build is marked as invalid" do
    project = Project.make(:steps => "ls /not/existing", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    assert_equal Build::STATUS_FAILED, build.status
  end

  test "special variable %build_dir% is available in steps" do
    project = Project.make(:steps => "ls -al file\nls %build_dir%", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    assert_equal Build::STATUS_OK, build.status
    assert build.stdout[-1][:output].include?("file")
  end

  test "special variable %project_dir% is available in steps" do
    project = Project.make(:steps => "ls -al file\nls %project_dir%", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    assert_equal Build::STATUS_OK, build.status
    assert build.stdout[-1][:output].include?(build.build_dir.split("/")[-1]) # build folder
  end

  test "if step produces white output then it should be set to nil" do
    project = Project.make(:steps => "cd %project_dir%", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    assert_equal Build::STATUS_OK, build.status
    assert_nil build.stdout[-1][:output]
  end
end
