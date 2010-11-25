require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
    @project = Project.make(:task => "ls -al file", :name => "Project", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 1)
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

  test "removing project removes its buils" do
    @project.build!
    @project.build!
    assert_difference("Build.count", -2) do
      @project.destroy
    end
  end
end
