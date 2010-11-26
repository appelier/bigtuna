require "integration_test_helper"

class BuildingTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
    @commit_hash = `cd test/files/repo; git log --format=%H --max-count=1`.strip
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/msqproject")
    super
  end

  test "if command fails we mark it on build view and show further commands as unexecuted" do
    project = Project.make(:steps => "git log\ngit diff crapper\nls -al", :name => "msqproject", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/"
    click_link_or_button "msqproject"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    visit "/"
    click_link_or_button "msqproject"
    click_link_or_button @commit_hash[0, 7]
    assert page.has_css?("#steps #step_1")
    assert page.has_css?("#steps #step_2")
    assert page.has_css?("#steps #step_3")
    assert page.has_css?("#steps #step_4")
    within("#steps #step_4") do
      assert page.has_content?("Task was not executed")
    end
  end
end
