require 'test_helper'

class MailerHookTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir koss; cd koss; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/koss")
    FileUtils.rm_rf("builds/koss")
    super
  end

  test "mail stating that build failed is sent when build failed" do
    project = mailing_project_with_steps("ls invalid_file_here")
    assert_difference("Delayed::Job.count", +2) do # 1 job, 1 email
      job = project.build!
      job.invoke_job
    end
    build = project.recent_build
    job = Delayed::Job.order("created_at DESC").first
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' failed", mail.subject
    assert ! mail.body.to_s.blank?
  end

  test "mail stating that build is back to normal is sent when build fixed" do
    project = mailing_project_with_steps("ls invalid_file_here")
    job = project.build!
    job.invoke_job
    project.update_attributes!(:steps => "ls .")
    assert_difference("Delayed::Job.count", +2) do # 1 job, 1 email
      job = project.build!
      job.invoke_job
    end
    build = project.recent_build
    job = Delayed::Job.order("created_at DESC").first
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' fixed", mail.subject
    assert ! mail.body.to_s.blank?
  end

  test "mail stating that build is still failing is sent when build still fails" do
    project = mailing_project_with_steps("ls invalid_file_here")
    job = project.build!
    job.invoke_job
    assert_difference("Delayed::Job.count", +2) do # 1 job, 1 email
      job = project.build!
      job.invoke_job
    end
    build = project.recent_build
    job = Delayed::Job.order("created_at DESC").first
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' still fails", mail.subject
    assert ! mail.body.to_s.blank?
  end

  test "mail is not sent when build is ok but was ok before" do
    project = mailing_project_with_steps("ls .")
    assert_difference("Delayed::Job.count", +2) do # 2 jobs, no mails
      2.times do
        job = project.build!
        job.invoke_job
      end
    end
  end

  def mailing_project_with_steps(steps)
    project = Project.make(:steps => steps, :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2, :hooks => {"mailer" => "mailer"})
    hook = project.hooks.first
    hook.configuration = {"recipients" => "michal.bugno@gmail.com"}
    hook.save!
    project
  end
end
