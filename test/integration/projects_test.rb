require "integration_test_helper"

class ProjectsTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/valid")
    FileUtils.rm_rf("builds/valid2")
    FileUtils.rm_rf("builds/invalid")
    super
  end

  test "one can successfully build a project" do
    project = Project.make(:steps => "ls -al file", :name => "Valid", :vcs_source => "test/files/repo", :vcs_type => "git")
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
    project = Project.make(:steps => "ls -al file_doesnt_exist", :name => "Invalid", :vcs_source => "test/files/repo", :vcs_type => "git")
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

  test "removing projects from list" do
    project = Project.make(:steps => "ls -al file", :name => "Valid", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/"
    click_link_or_button "Valid"
    click_link "Remove project"
    assert_difference("Project.count", -1) do
      click_button "Yes, I'm sure"
    end
  end

  test "user can reorder projects on project list" do
    project1 = Project.make(:steps => "echo 'ha'", :name => "Valid", :vcs_source => "test/files/repo", :vcs_type => "git")
    project2 = Project.make(:steps => "echo 'sa'", :name => "Valid2", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/"
    within("#project_#{project2.id}") do
      assert page.has_content?("Up")
      assert ! page.has_content?("Down")
    end
    within("#project_#{project1.id}") do
      assert page.has_content?("Down")
      assert ! page.has_content?("Up")
    end
    click_link "Down"
    within("#project_#{project1.id}") do
      assert page.has_content?("Up")
      assert ! page.has_content?("Down")
    end
    within("#project_#{project2.id}") do
      assert page.has_content?("Down")
      assert ! page.has_content?("Up")
    end
  end

  test "cannot build project with invalid repo" do
    project = Project.make(:steps => "echo 'ha'", :name => "Valid", :vcs_source => "no/such/repo", :vcs_type => "git")
    visit "/"
    click_link "Valid"
    assert_difference("Build.count", 0) do
      click_link "Build now"
    end
    assert page.has_content?("Repository not found under 'no/such/repo'")
  end
end
