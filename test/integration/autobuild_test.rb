require "integration_test_helper"

class AutobuildTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/*")
    super
  end

  test "if hook name is not found, 404 status is returned with appropriate description" do
    post "/hooks/build/not_found_halp"
    assert_status_code(404)
    assert response.body.include?("hook name \"not_found_halp\" not found")
  end

  test "if github posts hook we look for specified branch to build" do
    project1 = Project.make(:steps => "ls", :name => "obywatelgc", :vcs_source => "https://github.com/appelier/githubhook", :vcs_branch => "master", :vcs_type => "git", :max_builds => 2)
    project2 = Project.make(:steps => "ls", :name => "obywatelgc2", :vcs_source => "https://github.com/appelier/githubhook", :vcs_branch => "development", :vcs_type => "git", :max_builds => 2)
    token = BigTuna.github_secure

    assert_difference("project1.builds.count", +1) do
      assert_difference("project2.builds.count", 0) do
        post "/hooks/build/github/#{token}", :payload => "{\"ref\":\"refs/heads/master\",\"repository\":{\"url\":\"https://github.com/appelier/githubhook\"}}"
        assert_status_code(200)
        assert response.body.include?("build for \"#{project1.name}\" triggered")
      end
    end
  end

  test "github post with invalid token won't build anything" do
    project1 = Project.make(:steps => "ls", :name => "obywatelgc", :vcs_source => "https://github.com/appelier/githubhook", :vcs_branch => "master", :vcs_type => "git", :max_builds => 2)
    project2 = Project.make(:steps => "ls", :name => "obywatelgc2", :vcs_source => "https://github.com/appelier/githubhook", :vcs_branch => "development", :vcs_type => "git", :max_builds => 2)
    token = BigTuna.github_secure
    invalid_token = token + "a"

    assert_difference("Build.count", 0) do
      post "/hooks/build/github/#{invalid_token}", :payload => "{\"ref\":\"refs/heads/master\",\"repository\":{\"url\":\"https://github.com/appelier/githubhook\"}}"
      assert_status_code(404)
      assert response.body.include?("invalid secure token")
    end
  end
end
