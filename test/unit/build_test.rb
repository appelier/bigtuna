require 'test_helper'

class BuildTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir koss; cd koss; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/koss")
    FileUtils.rm_rf("builds/koss")
    super
  end

  test "invalid build is marked as invalid" do
    project = Project.make(:steps => "ls /not/existing", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert_equal Build::STATUS_FAILED, build.status
  end

  test "special variable %build_dir% is available in steps" do
    project = Project.make(:steps => "ls -al file\nls %build_dir%", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert build.stdout[-1].stdout.include?("file")
  end

  test "special variable %project_dir% is available in steps" do
    project = Project.make(:steps => "ls -al file\nls %project_dir%", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert build.stdout[-1].stdout.include?(build.build_dir.split("/")[-1]) # build folder
  end

  test "if step produces white output then it should be set to nil" do
    project = Project.make(:steps => "cd %project_dir%", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 1)
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert_nil build.stdout[-1].stdout
  end

  test "mail stating that build failed is sent when build failed" do
    project = Project.make(:steps => "ls invalid_file_here", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2)
    assert_difference("Delayed::Job.count", +2) do # 1 job, 1 email
      job = project.build!
      job.invoke_job
    end
    build = project.recent_build
    job = Delayed::Job.order("created_at DESC").first
    mail = YAML.load(job.handler).perform
    assert_equal "Build '#{build.display_name}' in '#{project.name}' failed", mail.subject
  end

  test "mail stating that build is back to normal is sent when build fixed" do
    project = Project.make(:steps => "ls invalid_file_here", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2)
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
  end

  test "mail stating that build is still failing is sent when build still fails" do
    project = Project.make(:steps => "ls invalid_file_here", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2)
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
  end

  test "mail is not sent when build is ok but was ok before" do
    project = Project.make(:steps => "ls .", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2)
    assert_difference("Delayed::Job.count", +2) do # 2 jobs, no mails
      2.times do
        job = project.build!
        job.invoke_job
      end
    end
  end

  test "build #to_param includes build display name and project name" do
    project = Project.make(:steps => "ls .", :name => "Koss", :vcs_source => "test/files/koss", :vcs_type => "git", :max_builds => 2)
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert build.to_param =~ /^#{build.id}/
    assert build.to_param.include?(project.name.to_url)
    assert build.to_param.include?(build.display_name.to_url)
  end
end
