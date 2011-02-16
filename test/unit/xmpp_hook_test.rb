require 'test_helper'

class XmppHookTest < ActiveSupport::TestCase

  include WithTestRepo

  test "xmpp message stating that build failed is sent when build failed" do
    BigTuna::Hooks::Xmpp::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = xmpp_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the xmpp message
      job = project.build!
      stub_xmpp(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' fixed")
      job.invoke_job
    end
  end

  test "xmpp message stating that build is back to normal is sent when build fixed" do
    BigTuna::Hooks::Xmpp::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = xmpp_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_xmpp(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' fixed")
    project.step_lists.first.update_attributes!(:steps => "ls .")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 xmpp message
  end

  test "xmpp message stating that build is still failing is sent when build still fails" do
    project = xmpp_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_xmpp(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' still fails")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 xmpp message
  end

  test "no xmpp message sent when build is ok but was ok before" do
    project = xmpp_project_with_steps("ls .")
    project.build!
    run_delayed_jobs()
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 2, jobs.size
  end

  private
  def xmpp_project_with_steps(steps)
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :vcs_type => "git",
      :max_builds => 2,
      :hooks => {"xmpp" => "xmpp"},
    }, steps)
    hook = project.hooks.first
    hook.configuration = {
      "recipients" => "user1@example.com,user2@example.com,user3@example.com",
      "sender_full_jid" => "thesender@example.com",
      "sender_password" => "secret"
    }

    hook.save!
    project
  end

  def stub_xmpp(hook, message)
    s = Mocha::Mock.new
    s.expects(:initialize).with(hook.configuration["sender_full_jid"], hook.configuration["sender_password"]).returns(s)
    hook.configuration["recipients"].to_s.split(",").each do |recipient|
      s.expects(:deliver).with(recipient).returns(s)
    end
    s
  end
end
