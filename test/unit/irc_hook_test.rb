require 'test_helper'

class IrcHookTest < ActiveSupport::TestCase

  include WithTestRepo

  test "IRC message stating that build failed is sent when build failed" do
    BigTuna::Hooks::Irc::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = irc_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the irc message
      job = project.build!
      stub_irc(hook, "New build in '#{project.name}' FAILED")
      job.invoke_job
    end
  end

  test "IRC message stating that build is back to normal is sent when build fixed" do
    BigTuna::Hooks::Irc::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = irc_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_irc(hook, "New build in '#{project.name}' FIXED")
    project.step_lists.first.update_attributes!(:steps => "ls .")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 irc notification
  end

  test "irc message stating that build is still failing is sent when build still fails" do
    BigTuna::Hooks::Irc::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = irc_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_irc(hook, "New build in '#{project.name}' STILL FAILS")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 irc notification
  end

  test "irc message sent when the build is still ok" do
    BigTuna::Hooks::Irc::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = irc_project_with_steps("ls .")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_irc(hook, "New build in '#{project.name}' STILL PASSES")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 irc notification
  end

  private
  def irc_project_with_steps(steps)
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :vcs_type => "git",
      :max_builds => 2,
      :hooks => {"irc" => "irc"},
    }, steps)
    hook = project.hooks.first
    hook.configuration = {
      "user_name" => "some_bot",
      "server" => "irc.someserver.net",
      "port" => "1234",
      "room" => "someroom",
      "room_password" => "secret"
    }

    hook.save!
    project
  end

  def stub_irc(hook, message)
    s = Mocha::Mock.new
    s.expects(:shout).with(message).returns(s)
    s
  end
end
