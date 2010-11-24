require "integration_test_helper"

class BuildingTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
  end

  test "one can successfully build a project" do
    project = Project.make(:task => "ls -al file", :name => "Valid", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/"
    click_link_or_button "Valid"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    visit "/"
    assert page.has_css?("#project_#{project.id}.#{Build::STATUS_OK}")
  end

  test "project build can fail" do
    project = Project.make(:task => "ls -al file_doesnt_exist", :name => "Invalid", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/"
    click_link_or_button "Invalid"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    visit "/"
    assert page.has_css?("#project_#{project.id}.#{Build::STATUS_FAILED}")
  end
end
