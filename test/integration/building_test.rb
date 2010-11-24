require "integration_test_helper"

class BuildingTest < ActionController::IntegrationTest
  test "one can successfully build a project" do
    project = Project.make(:task => "ls -al file", :name => "valid")
    visit "/"
    click_link_or_button "valid"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    visit project_path(project)
    assert page.has_content?("ok")
  end

  test "project build can fail" do
    project = Project.make(:task => "ls -al file_doesnt_exist", :name => "invalid")
    visit "/"
    click_link_or_button "invalid"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    visit project_path(project)
    assert ! page.has_content?("failure")
  end
end
