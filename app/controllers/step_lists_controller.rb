class StepListsController < ApplicationController
  before_filter :locate_project, :only => [:create, :update, :destroy]

  def create
    begin
      @step_list = @project.step_lists.build(params[:step_list])
      @step_list.save!
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.message
    end
    redirect_to edit_project_path(@project)
  end

  def update
    begin
      @step_list = @project.step_lists.find(params[:id])
      @step_list.update_attributes!(params[:step_list])
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.message
    end
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
