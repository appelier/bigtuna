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
    hook = BigTuna::Hooks::GitHub.new
    validate_token_and_respond(BigTuna.github_secure, hook)
  end

  def bitbucket
    hook = BigTuna::Hooks::Bitbucket.new
    validate_token_and_respond(BigTuna.bitbucket_secure, hook)
  end

  def configure
    @project = Project.find(params[:project_id])
    @hook = Hook.where(:project_id => @project.id, :hook_name => params[:name]).first
    return render if request.get?

    @hook.configuration = params["configuration"]
    @hook.hooks_enabled = (params["hooks_enabled"] || {}).keys
    @hook.save!
    redirect_to(project_config_hook_path(@project, @hook.backend.class::NAME))
  end

private

  def validate_token_and_respond(secure_token, hook)
    hook.parse(JSON.parse(params[:payload]))

    project = Project.where("(vcs_source = ? OR vcs_source = ?) AND vcs_branch = ?",
                              hook.vcs_sources[:public],
                              hook.vcs_sources[:private],
                              hook.vcs_branch).first

    if secure_token.nil? 
      render :text => "#{hook.class::NAME} secure token is not set up", :status => 403
    elsif project and params[:secure] == secure_token 
      trigger_and_respond(project)
    else
      render :text => "invalid secure token", :status => 404
    end
  end

  def trigger_and_respond(project)
    project.build!
    render :text => "build for %p triggered" % [project.name], :status => 200
  end

end
