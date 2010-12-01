require 'test_helper'

class XmppHookTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir koss; cd koss; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/koss")
    FileUtils.rm_rf("builds/koss")
    super
  end

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
    job = project.build!
    job.invoke_job
    stub_xmpp(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' fixed")
    project.update_attributes!(:steps => "ls .")
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the xmpp message
      job = project.build!
      job.invoke_job
    end
  end

  test "xmpp message stating that build is still failing is sent when build still fails" do
    project = xmpp_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    job = project.build!
    stub_xmpp(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' still fails")
    job.invoke_job
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the xmpp message
      job = project.build!
      job.invoke_job
    end
  end

  test "no xmpp message sent when build is ok but was ok before" do
    project = xmpp_project_with_steps("ls .")
    assert_difference("Delayed::Job.count", +2) do # 2 jobs, nothing sent via xmpp
      2.times do
        job = project.build!
        job.invoke_job
      end
    end
  end

  private
  def xmpp_project_with_steps(steps)
    project = Project.make(:steps => steps, :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2, :hooks => {"xmpp" => "xmpp"}, :hook_update => true)
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
    hook.configuration["recipients"].each do |recipient|
      s.expects(:deliver).with(recipient).returns(s)
    end
    s
  end
end
