class BuildsController < ApplicationController
  before_filter :locate_build, :only => [:show, :destroy]
  respond_to :js, :only => :show

  def show

  end

  def destroy
    project = @build.project
    @build.destroy
    redirect_to project_path(project)
  end

  private
  def locate_build
    @build = Build.find(params[:id])
  end
end
