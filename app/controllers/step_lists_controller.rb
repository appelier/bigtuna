class StepListsController < ApplicationController
  before_filter :locate_project, :only => [:create, :update, :destroy]

  def create
    @step_list = @project.step_lists.build(params[:step_list])
    @step_list.save!
    redirect_to edit_project_path(@project)
  end

  def update
    @step_list = @project.step_lists.find(params[:id])
    @step_list.update_attributes!(params[:step_list])
    redirect_to edit_project_path(@project)
  end

  def destroy
    @step_list = @project.step_lists.find(params[:id])
    @step_list.destroy
    redirect_to edit_project_path(@project)
  end

  private
  def locate_project
    @project = Project.find(params[:project_id])
  end
end
