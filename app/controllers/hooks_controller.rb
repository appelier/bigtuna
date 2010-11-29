class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def autobuild
    Project.where(:hook_name => params[:hook_name]).first.build!
    render :text => "ok", :status => 200
  end

  def configure
    @project = Project.find(params[:project_id])
    @hook = Hook.where(:project_id => @project.id, :hook_name => params[:name]).first
    return render if request.get?
    @hook.configuration = params["configuration"]
    @hook.save!
    redirect_to(project_config_hook_path(@project, @hook.backend::NAME))
  end
end
