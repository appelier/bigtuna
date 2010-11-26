require "integration_test_helper"

class ManagingBuildsTest < ActionController::IntegrationTest
  def setup
    super
    @output = `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"; git log --format=%H --max-count=1`
    @commit_hash = @output.split[-1]
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
end
