require "integration_test_helper"

class BuildsTest < ActionController::IntegrationTest
  def setup
    super
    @output = `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"; git log --format=%H --max-count=1`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/myproject")
    super
  end

  test "one can delete build" do
    project = Project.make(:steps => "ls -al file", :name => "myproject", :vcs_source => "test/files/repo", :vcs_type => "git")
    project.build!
    visit "/"
    click_link_or_button "myproject"
    build = Build.order("created_at DESC").first
    within("#build_#{build.id}") do
      assert_difference("Build.count", -1) do
        click_button "Delete"
      end
    end
  end

  test "if command fails we mark it on build view and show further commands as unexecuted" do
    project = Project.make(:steps => "git log\ngit diff crapper\nls -al", :name => "myproject", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/"
    click_link_or_button "myproject"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    visit "/"
    click_link_or_button "myproject"
    click_link_or_button "Build #1"
    assert page.has_css?("#steps #step_1")
    assert page.has_css?("#steps #step_2")
    assert page.has_css?("#steps #step_3")
    assert page.has_css?("#steps #step_4")
    within("#steps #step_4") do
      assert page.has_content?("Task was not executed")
    end
  end
end
