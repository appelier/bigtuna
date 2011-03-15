class SharedVariablesController < ApplicationController
  before_filter :fetch_step_list

  def index
    @shared_variables = @step_list.shared_variables
    @shared_variable = SharedVariable.new(params[:shared_variable])
  end

  def create
    @shared_variable = SharedVariable.new(params[:shared_variable])
    @shared_variable.step_list = @step_list
    @shared_variable.save!
    redirect_to shared_variables_path(:step_list_id => @step_list)
  end

  def update
    @shared_variable = SharedVariable.find(params[:id])
    @shared_variable.update_attributes!(params[:shared_variable])
    redirect_to shared_variables_path(:step_list_id => @step_list)
  end

  def destroy
    @shared_variable = SharedVariable.find(params[:id])
    @shared_variable.destroy
    redirect_to shared_variables_path(:step_list_id => @step_list)
  end

  private
  def fetch_step_list
    @step_list = StepList.find(params[:step_list_id])
  end
end
