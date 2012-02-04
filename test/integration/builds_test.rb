require "integration_test_helper"

class BuildsTest < ActionController::IntegrationTest

  include WithTestRepo

  test "one can delete build" do
    project = project_with_steps({:name => "myproject", :vcs_source => "test/files/repo", :vcs_type => "git"}, "ls -al file")
    project.build!
    visit "/"
    click_link_or_button "myproject"
    build = project.recent_build
    within('.in-recent-builds') do
      click_link_or_button "Build ##{build.id}"
    end
    within(".page-header .btn-group") do
      assert_difference("Build.count", -1) do
        click_button "Delete build"
      end
    end
  end

  test "if command fails we mark it on build view and show further commands as unexecuted" do
    project = project_with_steps({:name => "myproject", :vcs_source => "test/files/repo", :vcs_type => "git"}, "git log\ngit diff crapper\nls -al")
    visit "/"
    click_link_or_button "myproject"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    run_delayed_jobs()
    visit "/"
    click_link_or_button "myproject"
    within('.in-recent-builds') do
      click_link_or_button "#1"
    end
    assert page.has_css?("#step_1")
    assert page.has_css?("#step_2")
    assert page.has_css?("#step_3")
    within("#step_3") do
      assert page.has_content?("Task was not executed")
    end
  end

  test "if build is scheduled then visiting its page should work" do
    project = project_with_steps({:name => "myproject", :vcs_source => "test/files/repo", :vcs_type => "git"}, "true\ntrue\ntrue")
    visit "/"
    click_link_or_button "myproject"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    # run_delayed_jobs()
    visit build_path(project.recent_build)
  end

  test "edit project from build view" do
    project = project_with_steps({
      :name => "Valid",
      :vcs_source => "test/files/repo",
    }, "ls -al file")
    visit "/projects/#{[project.id, project.name.to_url].join("-")}"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    visit build_path(project.recent_build)
    within(".page-header .btn-group") do
      click_link_or_button "Edit project"
    end
    assert_equal current_path, "/projects/#{[project.id, project.name.to_url].join("-")}/edit"
  end

  test "test with no steps has green status after build" do
    project = Project.make(:name => "myproject", :vcs_source => "test/files/repo", :vcs_type => "git")
    visit "/projects/#{[project.id, project.name.to_url].join("-")}"
    click_link_or_button "Build now"
    run_delayed_jobs()
    visit "/projects/#{[project.id, project.name.to_url].join("-")}"
    assert page.has_css?("h1.status_build_ok")
  end
end
