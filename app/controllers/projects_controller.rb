class ProjectsController < ApplicationController
  before_filter :locate_project, :only => [:show, :build, :edit, :update, :remove, :destroy, :arrange, :feed]
  respond_to :js, :only => [:index, :show]
  
  
  def index
    @projects = Project.order("position ASC")
  end

  def show
    @builds = @project.builds.order("created_at DESC").limit(@project.max_builds).includes(:project, :parts).all
  end

  def feed
    @builds = @project.builds.order("created_at DESC").limit(@project.max_builds)
    respond_to do |format|
      format.atom
    end
  end

  def build
    @project.build!
    redirect_to(project_path(@project))
  rescue BigTuna::VCS::Error => e
    flash[:error] = e.message
    redirect_to project_path(@project)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    if @project.save
      redirect_to edit_project_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @project.update_attributes!(params[:project])
    redirect_to edit_project_path(@project)
  end

  def remove
  end

  def destroy
    @project.destroy
    redirect_to projects_path
  end

  def arrange
    if params[:up]
      @project.move_higher
    elsif params[:down]
      @project.move_lower
    end
    redirect_to projects_path
  end

  private
  def locate_project
    @project = Project.find(params[:id])
  end
end
