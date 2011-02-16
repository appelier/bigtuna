require 'test_helper'

class MailerHookTest < ActiveSupport::TestCase

  include WithTestRepo

  test "mail stating that build failed is sent when build failed" do
    project = mailing_project_with_steps("ls invalid_file_here")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 mail
    build = project.recent_build
    job = jobs.last
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' failed", mail.subject
    assert ! mail.body.to_s.blank?
  end

  test "mail stating that build is back to normal is sent when build fixed" do
    project = mailing_project_with_steps("ls invalid_file_here")
    project.build!
    run_delayed_jobs()
    project.step_lists.first.update_attributes!(:steps => "ls .")
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 mail
    build = project.recent_build
    job = jobs.last
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' fixed", mail.subject
    assert ! mail.body.to_s.blank?
  end

  test "mail stating that build is still failing is sent when build still fails" do
    project = mailing_project_with_steps("ls invalid_file_here")
    project.build!
    run_delayed_jobs()
    project.build!
    jobs = run_delayed_jobs()
    assert_equal 3, jobs.size # 1 project, 1 part, 1 mail
    build = project.recent_build
    job = jobs[-1]
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' still fails", mail.subject
    assert ! mail.body.to_s.blank?
  end

  test "mail is not sent when build is ok but was ok before" do
    project = mailing_project_with_steps("ls .")
    project.build!
    run_delayed_jobs()
    project.build!
    ran_jobs = run_delayed_jobs()
    assert_equal 2, ran_jobs.size
  end

  def mailing_project_with_steps(steps)
    project = project_with_steps({
       :name => "repo",
       :vcs_source => "test/files/repo",
       :max_builds => 2,
       :hooks => {"mailer" => "mailer"},
    }, steps)
    hook = project.hooks.first
    hook.configuration = {"recipients" => "michal.bugno@gmail.com"}
    hook.save!
    project
  end
end
