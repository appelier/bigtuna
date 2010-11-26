require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
    @project = Project.make(:steps => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/project")
    super
  end

  test "only recent builds are kept on disk" do
    assert_difference("Dir[File.join(@project.build_dir, '*')].size", +1) do
      job = @project.build!
      job.invoke_job
    end

    assert_difference("Dir[File.join(@project.build_dir, '*')].size", 0) do
      job = @project.build!
      job.invoke_job
    end
  end

  test "removing project removes its builds" do
    @project.build!
    @project.build!
    assert_difference("Build.count", -2) do
      @project.destroy
    end
  end

  test "stdout is grouped by command" do
    project = Project.make(:steps => "git diff file\necho 'lol'", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    steps = build.stdout
    assert_equal 3, steps.size # 2 + clone task
    assert_equal "git diff file 2>&1", steps[1][:command]
    assert_equal "echo 'lol' 2>&1", steps[2][:command]
    assert_equal Build::STATUS_OK, build.status
  end

  test "build is stopped when task returns with non-zero exit code" do
    project = Project.make(:steps => "ls -al file\nls -al not_a_file\necho 'not_here'", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    steps = build.stdout
    assert_equal 3, steps.size # 2 + clone task
    assert_equal "ls -al file 2>&1", steps[1][:command]
    assert_equal "ls -al not_a_file 2>&1", steps[2][:command]
    assert_equal Build::STATUS_FAILED, build.status
  end
end
