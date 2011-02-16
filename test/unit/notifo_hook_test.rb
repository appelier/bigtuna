require 'test_helper'

class NotifoHookTest < ActiveSupport::TestCase

  include WithTestRepo

  test "notifo message stating that build failed is sent when build failed" do
    BigTuna::Hooks::Notifo::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = notifo_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    assert_difference("Delayed::Job.count", +2) do # 1 job + 1 for sending the notifo message
      job = project.build!
      stub_notifo(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' fixed")
      job.invoke_job
    end
  end

  test "notifo message stating that build is back to normal is sent when build fixed" do
    BigTuna::Hooks::Notifo::Job.any_instance.expects(:perform).at_least_once.returns(true)

    project = notifo_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_notifo(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' fixed")
    project.step_lists.first.update_attributes!(:steps => "ls .")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 notifo message
  end

  test "notifo message stating that build is still failing is sent when build still fails" do
    project = notifo_project_with_steps("ls invalid_file_here")
    hook = project.hooks.first
    project.build!
    run_delayed_jobs()
    stub_notifo(hook, "Build '#{project.recent_build.display_name}' in '#{project.name}' still fails")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 notifo message
  end

  test "no notifo message sent when build is ok but was ok before" do
    project = notifo_project_with_steps("ls .")
    project.build!
    run_delayed_jobs()
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 2, jobs.size
  end

  private
  def notifo_project_with_steps(steps)
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :vcs_type => "git",
      :max_builds => 2,
      :hooks => {"notifo" => "notifo"},
    }, steps)
    hook = project.hooks.first
    hook.configuration = {
      "recipients" => "foo,bar",
      "user" => "foo",
      "key" => "secret"
    }

    hook.save!
    project
  end

  def stub_notifo(hook, message)
    mock = Mocha::Mock.new
    mock.expects(:initialize).with(hook.configuration["user"], hook.configuration["key"]).returns(mock)
    hook.configuration["recipients"].to_s.split(",").each do |recipient|
      mock.expects(:deliver).with(recipient).returns(mock)
    end
    mock
  end
end
