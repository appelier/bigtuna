class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def autobuild
    project = Project.where(:hook_name => params[:hook_name]).first
    if project
      trigger_and_respond(project)
    else
      render :text => "hook name %p not found" % [params[:hook_name]], :status => 404
    end
  end

  def github
    payload = JSON.parse(params[:payload])
    branch = payload["ref"].split("/").last
    url = payload["repository"]["url"]
    source = url.gsub(/^https:\/\//, "git://") + ".git"
    project = Project.where(:vcs_source => source, :vcs_branch => branch).first
    if BigTuna.github_secure.nil?
      render :text => "github secure token is not set up", :status => 403
    elsif project and params[:secure] == BigTuna.github_secure
      trigger_and_respond(project)
    else
      render :text => "invalid secure token", :status => 404
    end
  end

  def configure
    @project = Project.find(params[:project_id])
    @hook = Hook.where(:project_id => @project.id, :hook_name => params[:name]).first
    return render if request.get?
    @hook.configuration = params["configuration"]
    @hook.save!
    redirect_to(project_config_hook_path(@project, @hook.backend::NAME))
  end

  private
  def trigger_and_respond(project)
    project.build!
    render :text => "build for %p triggered" % [project.name], :status => 200
  end
end
