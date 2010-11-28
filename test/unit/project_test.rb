require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/project")
    super
  end

  test "only recent builds are kept on disk" do
    project = Project.make(:steps => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    assert_difference("Dir[File.join(project.build_dir, '*')].size", +1) do
      job = project.build!
      job.invoke_job
    end

    assert_difference("Dir[File.join(project.build_dir, '*')].size", 0) do
      job = project.build!
      job.invoke_job
    end
  end

  test "removing project removes its builds" do
    project = Project.make(:steps => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    project.build!
    project.build!
    assert_difference("Build.count", -2) do
      project.destroy
    end
  end

  test "stdout is grouped by command" do
    project = Project.make(:steps => "git diff file\necho 'lol'", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    steps = build.stdout
    assert_equal 3, steps.size # 2 + clone task
    assert_equal "git diff file", steps[1].command
    assert_equal 0, steps[1].exit_code
    assert_equal "echo 'lol'", steps[2].command
    assert_equal 0, steps[2].exit_code
    assert_equal Build::STATUS_OK, build.status
  end

  test "build is stopped when task returns with non-zero exit code" do
    project = Project.make(:steps => "ls -al file\nls -al not_a_file\necho 'not_here'", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.builds.order("created_at DESC").first
    steps = build.stdout
    assert_equal 4, steps.size # all steps, but not all were executed
    assert_equal "ls -al file", steps[1].command
    assert_equal 0, steps[1].exit_code
    assert_equal "ls -al not_a_file", steps[2].command
    assert steps[2].exit_code != 0
    assert_nil steps[3].exit_code
    assert_nil steps[3].stdout
    assert_equal "echo 'not_here'", steps[3].command
    assert_equal Build::STATUS_FAILED, build.status
  end

  test "removing project removes its build folder" do
    project = Project.make(:steps => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    assert File.exist?(project.build_dir)
    assert_difference("Dir[File.join('builds', '*')].size", -1) do
      project.destroy
    end
    assert ! File.exist?(project.build_dir)
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

  test "project name should be unique" do
    name = "unique project name"
    Project.make(:name => name)
    assert_invalid(Project, :name) { |p| p.name = name }
  end

  test "project name should be present" do
    assert_invalid(Project, :name) { |p| p.name = "" }
  end

  test "project dir should be renamed if project name changes" do
    begin
      project = Project.make(:name => "my name", :steps => "ls -al")
      dir = project.send(:build_dir_from_name, project.name)
      job = project.build!
      job.invoke_job
      assert File.directory?(dir)
      project.name = "my other name"
      project.save!
      assert ! File.directory?(dir)
      job = project.build!
      job.invoke_job
      new_dir = project.send(:build_dir_from_name, project.name)
      assert File.directory?(new_dir)
    ensure
      FileUtils.rm_rf("builds/my_name")
      FileUtils.rm_rf("builds/my_other_name")
    end
  end

  test "vcs_type should be one of vcs types available" do
    invalid_backend = "lol"
    assert ! BigTuna::VCS_BACKENDS.include?(invalid_backend)
    assert_invalid(Project, :vcs_type) { |p| p.vcs_type = invalid_backend }
  end

  test "vcs_source should be present" do
    assert_invalid(Project, :vcs_source) { |p| p.vcs_source = "" }
  end

  test "vcs_branch should be present" do
    assert_invalid(Project, :vcs_branch) { |p| p.vcs_branch = "" }
  end

  test "total_builds gets increased" do
    project = Project.make(:steps => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
    assert_equal 0, project.total_builds
    project.build!
    project.build!

    project.reload
    assert_equal 2, project.total_builds
  end

  test "stability is computed properly" do
    project = Project.make(:steps => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git")
    project.update_attributes!(:total_builds => 3, :failed_builds => 1)
    assert_in_delta 0.66, project.stability, 0.01
  end
end
