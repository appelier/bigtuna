require "integration_test_helper"

class ProjectsTest < ActionController::IntegrationTest

  include WithTestRepo

  test "user can add a project" do
    visit "/"
    click_link "New project"
    fill_in "Name", :with => "My shiny project"
    select "Git", :from => "Vcs type"
    fill_in "Vcs source", :with => "test/files/repo"
    fill_in "Vcs branch", :with => "master"
    fill_in "Max builds", :with => "3"
    fill_in "Hook name", :with => "myshinyproject"
    assert_difference("Project.count", +1) do
      click_button "Create"
    end
    within("#new_step_list") do
      fill_in "Name", :with => "my name"
      fill_in "Steps", :with => "ls -al ."
      click_button "Create"
    end
  end

  test "user can duplicate a project" do
    project = project_with_steps({
      :name => "Project to duplicate",
      :vcs_source => " test/files/repo",
    }, "ls -al file")
    visit "/"
    click_link_or_button("Project to duplicate")
    click_link_or_button("Duplicate")
    assert page.has_content?("Project to duplicate COPY")
  end

  test "one can successfully build a project" do
    project = project_with_steps({
      :name => "Valid",
      :vcs_source => "test/files/repo",
    }, "ls -al file")
    visit "/"
    click_link_or_button "Valid"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    run_delayed_jobs()
    visit "/"
    assert page.has_css?("#project_#{project.id}.#{Build::STATUS_OK}")
  end

  test "project build can fail" do
    project = project_with_steps({
      :name => "Invalid",
      :vcs_source => "test/files/repo",
    }, "ls -al file_doesnt_exist")
    visit "/"
    click_link_or_button "Invalid"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
    run_delayed_jobs()
    visit "/"
    assert page.has_css?("#project_#{project.id}.#{Build::STATUS_FAILED}")
  end

  test "removing projects from list" do
    project = project_with_steps({
      :name => "Valid",
      :vcs_source => "test/files/repo",
    }, "ls -al file")
    visit "/"
    click_link_or_button "Valid"
    click_link "Remove project"
    assert_difference("Project.count", -1) do
      click_button "Yes, I'm sure"
    end
  end

  test "user can reorder projects on project list" do
    project1 = project_with_steps({
      :name => "Valid",
      :vcs_source => "test/files/repo",
    }, "echo 'ha'")
    project2 = project_with_steps({
      :name => "Valid2",
      :vcs_source => "test/files/repo",
    }, "echo 'ha'")
    visit "/"
    within("#project_#{project2.id} .updown") do
      assert page.has_xpath?("a[contains(@href, 'up=')]")
      assert ! page.has_xpath?("a[contains(@href, 'down=')]")
    end
    within("#project_#{project1.id} .updown") do
      assert page.has_xpath?("a[contains(@href, 'down')]")
      assert ! page.has_xpath?("a[contains(@href, 'up')]")
    end

    click_link "\342\206\223"
    within("#project_#{project1.id} .updown") do
      assert page.has_xpath?("a[contains(@href, 'up=')]")
      assert ! page.has_xpath?("a[contains(@href, 'down=')]")
    end
    within("#project_#{project2.id} .updown") do
      assert page.has_xpath?("a[contains(@href, 'down')]")
      assert ! page.has_xpath?("a[contains(@href, 'up')]")
    end
  end

  test "project with invalid repo shows appropriate errors" do
    project = project_with_steps({
      :name => "Valid",
      :vcs_source => "no/such/repo",
    }, "echo 'ha'")
    visit "/"
    click_link "Valid"
    assert_difference("Build.count", +1) do
      click_link "Build now"
    end
    build = project.recent_build
    job = Delayed::Job.order("created_at DESC").first
    job.invoke_job
    click_link build.display_name
    assert page.has_content?("fatal: repository 'no/such/repo' does not exist")
  end

  test "project should have a link to the atom feed" do
    project = project_with_steps({
      :name => "Atom project",
      :vcs_source => "no/such/repo",
    }, "echo 'ha'")
    visit "/projects/#{[project.id, project.name.to_url].join("-")}"
    assert page.has_link?("Feed")
  end

  test "project should have an atom feed" do
    project = project_with_steps({
      :name => "Atom project 2",
      :vcs_source => "no/such/repo",
      :max_builds => 3,
    }, "echo 'ha'")
    build_1 = Build.make(:project => project, :created_at => 2.weeks.ago)
    build_2 = Build.make(:project => project, :created_at => 1.week.ago)
    visit "/projects/#{[project.id, project.name.to_url].join("-")}/feed.atom"
    parsed = Crack::XML.parse(page.body)
    assert_equal "Atom project 2 CI", parsed["feed"]["title"]
    assert_equal 2, parsed["feed"]["entry"].size
    assert_equal "#{build_1.display_name} - #{build_1.status == Build::STATUS_OK ? "SUCCESS" : "FAILED"}", parsed["feed"]["entry"][0]["title"]
    assert_equal "#{build_2.display_name} - #{build_2.status == Build::STATUS_OK ? "SUCCESS" : "FAILED"}", parsed["feed"]["entry"][1]["title"]
  end

  test "navigating to project details on edit" do
    project = project_with_steps({
      :name => "Atom project 2",
      :vcs_source => "no/such/repo",
      :max_builds => 3,
    }, "echo 'ha'")
    visit "/projects/#{[project.id, project.name.to_url].join("-")}/edit"
    within("#sidebar") do
      click_link_or_button "Project"
    end
    assert_equal current_path, "/projects/#{[project.id, project.name.to_url].join("-")}"
  end

  test "building the project from edit view" do
    project = project_with_steps({
      :name => "Valid",
      :vcs_source => "test/files/repo",
    }, "ls -al file")
    visit "/projects/#{[project.id, project.name.to_url].join("-")}/edit"
    assert_difference("Delayed::Job.count", +1) do
      click_link_or_button "Build now"
    end
  end
end
