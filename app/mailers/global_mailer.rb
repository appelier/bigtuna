class GlobalMailer < ActionMailer::Base
  default :from => "info@ci.appelier.com"

  def build_failed(build)
    @build = build
    @project = @build.project
    recipients = @project.recipients
    mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' failed")
  end

  def build_still_fails(build)
    @build = build
    @project = @build.project
    recipients = @project.recipients
    mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' still fails")
  end

  def build_fixed(build)
    @build = build
    @project = @build.project
    recipients = @project.recipients
    mail(:to => recipients, :subject => "Build '#{@build.display_name}' in '#{@project.name}' fixed")
  end
end
