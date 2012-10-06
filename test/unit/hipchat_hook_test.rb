require 'test_helper'

class HipchatHookTest < ActiveSupport::TestCase

  include WithTestRepo

  def setup
    super
    stub_request(:post, "https://api.hipchat.com/v1/rooms/message").
      to_return(:status => 200, :body => "", :headers => {})

    Build.any_instance.stubs(:author).returns('Bob')
  end

  test "hipchat stating the build failed" do
    project = hipchat_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the hipchat message
      job = project.build!
      job.invoke_job
    end
    build = project.recent_build
    jobs = run_delayed_jobs()

    result = jobs.last.payload_object.perform
    commit_sha = build.commit[0..6]
    assert_equal "Build failed in #{project.name}: #{build.commit_message} (#{commit_sha} by #{build.author})", result[:message]
  end

  test "hipchat stating build is back to normal" do
    project = hipchat_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    project.step_lists.first.update_attributes!(:steps => "ls .")
    project.build!

    jobs = run_delayed_jobs()
    build = project.recent_build
    assert_equal 3, jobs.size # 1 project, 1 part, 1 hipchat message

    result = jobs.last.payload_object.perform
    commit_sha = build.commit[0..6]
    assert_equal "Build fixed in #{project.name}: #{build.commit_message} (#{commit_sha} by #{build.author})", result[:message]
  end

  test "hipchat stating build still fails" do
    project = hipchat_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    project.build!

    jobs = run_delayed_jobs()
    build = project.recent_build
    assert_equal 3, jobs.size # 1 project, 1 part, 1 hipchat message

    result = jobs.last.payload_object.perform
    commit_sha = build.commit[0..6]
    assert_equal "Build still fails in #{project.name}: #{build.commit_message} (#{commit_sha} by #{build.author})", result[:message]
  end

  test "when the project is on github, a better message is generated" do
    project = hipchat_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the hipchat message
      job = project.build!
      job.invoke_job
    end
    build = project.recent_build
    build.project.update_attribute :vcs_source, 'git@github.com:appelier/bigtuna.git'
    jobs = run_delayed_jobs()
    result = jobs.last.payload_object.perform
    commit_sha = build.commit[0..6]
    assert_match "Build failed in #{project.name}", result[:message]
    assert_match "https://github.com/appelier/bigtuna/commit/#{build.commit}", result[:message]
    assert_match "#{build.commit_message}", result[:message]
    assert_match "#{commit_sha} by #{build.author}", result[:message]
  end

  test "hipchat does not send when build is ok but was ok before" do
    project = hipchat_project_with_steps("ls .")
    project.build!
    run_delayed_jobs()
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 2, jobs.size
  end

  private
    def hipchat_project_with_steps(steps)
      project = project_with_steps({
        :name => 'repo',
        :vcs_source => 'test/files/repo',
        :vcs_type => 'git',
        :max_builds => 2,
        :hooks => {"hipchat" => "hipchat"},
      }, steps)
      hook = project.hooks.first
      hook.configuration = {
        :room_id => '1234',
        :token => 'foobar'
      }
      hook.save!
      project
    end
end

