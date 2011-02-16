require "integration_test_helper"

class AutobuildTest < ActionController::IntegrationTest

  include WithTestRepo

  test "if hook name is not found, 404 status is returned with appropriate description" do
    post "/hooks/build/not_found_halp"
    assert_status_code(404)
    assert response.body.include?("hook name \"not_found_halp\" not found")
  end

  test "if github posts hook we look for specified branch to build" do
    project1 = github_project(:name => "obywatelgc", :vcs_branch => "master")
    project2 = github_project(:name => "obywatelgc2", :vcs_branch => "development")
    old_token = BigTuna.config[:github_secure]
    begin
      BigTuna.config[:github_secure] = "mytoken"
      token = BigTuna.github_secure
      assert_difference("project1.builds.count", +1) do
        assert_difference("project2.builds.count", 0) do
          post "/hooks/build/github/#{token}", :payload => github_payload(project1)
          assert_status_code(200)
          assert response.body.include?("build for \"#{project1.name}\" triggered")
        end
      end
    ensure
      BigTuna.config[:github_secure] = old_token
    end
  end

  test "github post for a private repo will build correctly" do
    project = github_project(:name => 'seotool', :vcs_branch => 'master',
                             :vcs_source => "git@github.com:company/secretrepo.git")
    old_token = BigTuna.config[:github_secure]
    begin
      BigTuna.config[:github_secure] = "mytoken"
      token = BigTuna.github_secure
      assert_difference("project.builds.count", +1) do
        post "/hooks/build/github/#{token}", :payload => github_payload(project)
        assert_status_code(200)
        assert response.body.include?("build for \"#{project.name}\" triggered")
      end
    ensure
      BigTuna.config[:github_secure] = old_token
    end
  end

  test "github post with invalid token won't build anything" do
    project1 = github_project(:name => "obywatelgc", :vcs_branch => "master")
    project2 = github_project(:name => "obywatelgc2", :vcs_branch => "development")
    old_token = BigTuna.config[:github_secure]
    begin
      BigTuna.config[:github_secure] = "mytoken"
      token = BigTuna.github_secure
      invalid_token = token + "a"
      assert_difference("Build.count", 0) do
        post "/hooks/build/github/#{invalid_token}", :payload => github_payload(project1)
        assert_status_code(404)
        assert response.body.include?("invalid secure token")
      end
    ensure
      BigTuna.config[:github_secure] = old_token
    end
  end

  test "github token has to be set up" do
    project1 = github_project(:name => "obywatelgc", :vcs_branch => "master")
    old_token = BigTuna.config[:github_secure]
    begin
      BigTuna.config[:github_secure] = nil
      assert_equal nil, BigTuna.github_secure
      post "/hooks/build/github/4ff", :payload => github_payload(project1)
      assert_status_code(403)
      assert response.body.include?("github secure token is not set up")
    ensure
      BigTuna.config[:github_secure] = old_token
    end
  end

  private
  def github_project(opts = {})
    project = Project.make({:vcs_source => "git://github.com/appelier/bigtuna.git", :vcs_branch => "master", :vcs_type => "git", :max_builds => 2}.merge(opts))
    step_list = StepList.make(:project => project, :steps => "ls")
    project
  end

  def github_payload(project)
    match = project.vcs_source.match(/github\.com(?:\/|:)(.+)$/)
    name = match[1].strip.gsub(/\.git$/, '')
    url = "https://github.com/#{name}"

    payload = {
      "ref" => "refs/heads/#{project.vcs_branch}",
      "repository" => { "url" => url },
    }
    payload.to_json
  end
end
