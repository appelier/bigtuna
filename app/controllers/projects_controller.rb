class ProjectsController < ApplicationController
  def index
    @projects = Project.order("created_at DESC")
  end

  def show
    @project = Project.find(params[:id])
    @builds = @project.builds.order("created_at DESC")
  end

  def build
    @project = Project.find(params[:id])
    @project.build!
    redirect_to(project_path(@project))
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    if @project.save
      redirect_to project_path(@project)
    else
      render :new
    end
  end
end
