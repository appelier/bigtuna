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
    assert_equal "git diff file", steps[1][:command]
    assert_equal 0, steps[1][:exit_code]
    assert_equal "echo 'lol'", steps[2][:command]
    assert_equal 0, steps[2][:exit_code]
    assert_equal Build::STATUS_OK, build.status
  end

  test "build is stopped when task returns with non-zero exit code" do
    project = Project.make(:steps => "ls -al file\nls -al not_a_file\necho 'not_here'", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    steps = build.stdout
    assert_equal 4, steps.size # all steps, but not all were executed
    assert_equal "ls -al file", steps[1][:command]
    assert_equal 0, steps[1][:exit_code]
    assert_equal "ls -al not_a_file", steps[2][:command]
    assert steps[2][:exit_code] != 0
    assert_nil steps[3][:exit_code]
    assert_nil steps[3][:output]
    assert_equal "echo 'not_here'", steps[3][:command]
    assert_equal Build::STATUS_FAILED, build.status
  end

  test "removing project removes its build folder" do
    job = @project.build!
    job.invoke_job
    assert File.exist?(@project.build_dir)
    assert_difference("Dir[File.join('builds', '*')].size", -1) do
      @project.destroy
    end
    assert ! File.exist?(@project.build_dir)
  end

  test "hook_name should be unique" do
    hook_name = "my_unique_hook_name"
    Project.make(:hook_name => hook_name)
    assert_invalid(Project, :hook_name) { |p| p.hook_name = hook_name }
  end

  test "if hook_name is empty it can be not-unique" do
    Project.make(:hook_name => "")
    Project.make(:hook_name => "")
  end
end
