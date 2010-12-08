require "integration_test_helper"

class StepListTest < ActionController::IntegrationTest
  def setup
    super
    @project = Project.make(:name => "my project")
    @step1 = StepList.make(:name => "short", :project => @project, :steps => "ls")
    @step2 = StepList.make(:name => "long", :project => @project, :steps => "ls -al\ntrue")
  end

  test "user can remove step list from project" do
    visit edit_project_path(@project)
    within("#remove_step_list_#{@step1.id}") do
      assert_difference("StepList.count", -1) do
        click_button "Remove"
      end
    end
  end

  test "user can update step list in project" do
    visit edit_project_path(@project)
    new_name = "not long"
    new_steps = "ls ."
    within("#edit_step_list_#{@step2.id}") do
      fill_in "Name", :with => new_name
      fill_in "Steps", :with => new_steps
      click_button "Update"
    end
    @step2.reload
    assert_equal new_name, @step2.name
    assert_equal new_steps, @step2.steps
  end
end
