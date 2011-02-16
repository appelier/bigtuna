require "integration_test_helper"

class BitbucketAutobuildTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; hg init; echo "my file" > file; hg add file; hg commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    super
  end

  test "if hook name is not found, 404 status is returned with appropriate description" do
    post "/hooks/build/not_found_halp"
    assert_status_code(404)
    assert response.body.include?("hook name \"not_found_halp\" not found")
  end

  test "if bitbucket posts hook we look for specified branch to build" do
    project1 = bitbucket_project(:name => "obywatelgc", :vcs_branch => "default")
    project2 = bitbucket_project(:name => "obywatelgc2", :vcs_branch => "development")
    old_token = BigTuna.config[:bitbucket_secure]
    begin
      BigTuna.config[:bitbucket_secure] = "mytoken"
      token = BigTuna.bitbucket_secure
      assert_difference("project1.builds.count", +1) do
        assert_difference("project2.builds.count", 0) do
          post "/hooks/build/bitbucket/#{token}", :payload => bitbucket_payload(project1)
          assert_status_code(200)
          assert response.body.include?("build for \"#{project1.name}\" triggered")
        end
      end
    ensure
      BigTuna.config[:bitbucket_secure] = old_token
    end
  end

  test "bitbucket post with invalid token won't build anything" do
    project1 = bitbucket_project(:name => "obywatelgc", :vcs_branch => "default")
    project2 = bitbucket_project(:name => "obywatelgc2", :vcs_branch => "development")
    old_token = BigTuna.config[:bitbucket_secure]
    begin
      BigTuna.config[:bitbucket_secure] = "mytoken"
      token = BigTuna.bitbucket_secure
      invalid_token = token + "a"
      assert_difference("Build.count", 0) do
        post "/hooks/build/bitbucket/#{invalid_token}", :payload => bitbucket_payload(project1)
        assert_status_code(404)
        assert response.body.include?("invalid secure token")
      end
    ensure
      BigTuna.config[:bitbucket_secure] = old_token
    end
  end

  test "bitbucket token has to be set up" do
    project1 = bitbucket_project(:name => "obywatelgc", :vcs_branch => "default")
    old_token = BigTuna.config[:bitbucket_secure]
    begin
      BigTuna.config[:bitbucket_secure] = nil
      assert_equal nil, BigTuna.bitbucket_secure
      post "/hooks/build/bitbucket/4ff", :payload => bitbucket_payload(project1)
      assert_status_code(403)
      assert response.body.include?("bitbucket secure token is not set up")
    ensure
      BigTuna.config[:bitbucket_secure] = old_token
    end
  end

  private
  def bitbucket_project(opts = {})
    project = Project.make({:vcs_source => "ssh://hg@bitbucket.org/foo/bigtuna/", :vcs_branch => "default", :vcs_type => "hg", :max_builds => 2}.merge(opts))
    step_list = StepList.make(:project => project, :steps => "ls")
    project
  end

  def bitbucket_payload(project)
    "{\"repository\": {\"owner\": \"foo\", \"website\": \"\", \"absolute_url\": \"/foo/bigtuna/\", \"slug\": \"bigtuna\", \"name\": \"bigtuna\"}, \"commits\": [{\"node\": \"94608d070caf\", \"files\": [{\"type\": \"modified\", \"file\": \"app/controllers/hooks_controller.rb\"}], \"author\": \"unsay\", \"timestamp\": \"2010-12-09 04:59:38\", \"raw_node\": \"94608d070caf01aeb60c39e099c528cebf62e9eb\", \"parents\": [\"e069646e9522\"], \"branch\": \"default\", \"message\": \"Ahh.\", \"size\": 57, \"revision\": 10}], \"user\": \"merp\"}"
  end
end
