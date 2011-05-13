require "integration_test_helper"

class AutobuildTest < ActionController::IntegrationTest

  include WithTestRepo

  test "if hook name is not found, 404 status is returned with appropriate description" do
    post "/hooks/build/not_found_halp"
    assert_status_code(404)
    assert response.body.include?("hook name \"not_found_halp\" not found")
  end

  test "if github project does not exist in bigtuna, return 404" do
    with_github_token do
      post("/hooks/build/github/#{@token}",
           :payload => {
             'ref' => 'refs/heads/master',
             'repository' => { 'url' => 'http://github.com/not/here.git' } }.to_json)
      assert_status_code(404)
      assert response.body.include?("project not found")
    end
  end

  test "look for github-specified branch to build" do
    project1 = github_project(:name => "obywatelgc", :vcs_branch => "master")
    project2 = github_project(:name => "obywatelgc2", :vcs_branch => "development")
    with_github_token do
      assert_difference("project1.builds.count", +1) do
        assert_difference("project2.builds.count", 0) do
          post "/hooks/build/github/#{@token}", :payload => github_payload(project1)
          assert_status_code(200)
          assert response.body.include?(%{build for the following projects were triggered: "#{project1.name}"})
        end
      end
    end
  end

  test "build all projects that match name and branch specified by github" do
    project1 = github_project(:name => "obywatelgc", :vcs_branch => "master")
    project2 = github_project(:name => "obywatelgc2", :vcs_branch => "master")
    with_github_token do
      assert_difference("project1.builds.count", +1) do
        assert_difference("project2.builds.count", +1) do
          post "/hooks/build/github/#{@token}", :payload => github_payload(project1)
          assert_status_code(200)
          assert response.body.include?(%{build for the following projects were triggered: "#{project1.name}", "#{project2.name}"})
        end
      end
    end
  end

  test "github post for a private 'git@' repo will build correctly" do
    project = github_project(:name => 'seotool', :vcs_branch => 'master',
                             :vcs_source => "git@github.com:company/secretrepo.git")
    with_github_token do
      assert_difference("project.builds.count", +1) do
        post "/hooks/build/github/#{@token}", :payload => github_payload(project)
        assert_status_code(200)
        assert response.body.include?(%{build for the following projects were triggered: "#{project.name}"})
      end
    end
  end

  test "github post for a private 'https://' repo will build correctly" do
    project = github_project(:name => 'seotool', :vcs_branch => 'master',
                             :vcs_source => "https://username:password@github.com/company/secretrepo.git")
    with_github_token do
      assert_difference("project.builds.count", +1) do
        post "/hooks/build/github/#{@token}", :payload => github_payload(project)
        assert_status_code(200)
        assert response.body.include?(%{build for the following projects were triggered: "#{project.name}"})
      end
    end
  end

  test "github post with invalid token won't build anything" do
    project = github_project(:name => "obywatelgc", :vcs_branch => "master")
    with_github_token do
      invalid_token = @token + "a"
      assert_difference("Build.count", 0) do
        post "/hooks/build/github/#{invalid_token}", :payload => github_payload(project)
        assert_status_code(403)
        assert response.body.include?("invalid secure token")
      end
    end
  end

  test "github token has to be set up" do
    project1 = github_project(:name => "obywatelgc", :vcs_branch => "master")
    with_github_token(nil) do
      assert_equal nil, BigTuna.github_secure
      post "/hooks/build/github/4ff", :payload => github_payload(project1)
      assert_status_code(403)
      assert response.body.include?("github secure token is not set up")
    end
  end

  private
  def github_project(opts = {})
    project = Project.make({:vcs_source => "git://github.com/appelier/bigtuna.git", :vcs_branch => "master", :vcs_type => "git", :max_builds => 2}.merge(opts))
    step_list = StepList.make(:project => project, :steps => "ls")
    project
  end

  def with_github_token(token = Array.new(8) { ('a'..'z').to_a.sample }.join)
    @token = token
    old_token = BigTuna.config[:github_secure]
    begin
      BigTuna.config[:github_secure] = token
      yield
    ensure
      BigTuna.config[:github_secure] = old_token
      @token = nil
    end
  end

  def github_payload(project)
    name = project.vcs_source.match( %r{github\.com[/:](.+)\.git$} )[1]
    url = "https://github.com/#{name}"

    payload = {
      "ref" => "refs/heads/#{project.vcs_branch}",
      "repository" => { "url" => url },
    }
    payload.to_json
  end
end
