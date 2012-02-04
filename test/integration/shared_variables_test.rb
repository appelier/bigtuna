require "integration_test_helper"

class SharedVariablesTest < ActionController::IntegrationTest
  def setup
    super
    @project = Project.make(:name => "my project")
    @step = StepList.make(:name => "short", :project => @project, :steps => "ls")
    visit edit_project_path(@project)
    click_link "Edit configuration specific variables"
  end

  test "user can add shared variable to step" do
    fill_in "Name", :with => "myname"
    fill_in "Value", :with => "myvalue"
    assert_difference("SharedVariable.count", +1) do
      click_button "Create"
    end
  end

  test "user can remove shared variable from step" do
    SharedVariable.create!(:name => "name", :value => "value", :step_list => @step)
    visit edit_project_path(@project)
    click_link "Edit configuration specific variables"
    assert_difference("SharedVariable.count", -1) do
      click_button "Remove"
    end
  end

  test "user can update shared variable in step" do
    v = SharedVariable.create!(:name => "name", :value => "value", :step_list => @step)
    visit edit_project_path(@project)
    click_link "Edit configuration specific variables"
    within("#edit_shared_variable_#{v.id}.form-horizontal") do
      fill_in "Name", :with => "newname"
      fill_in "Value", :with => "newvalue"
      click_button "Update"
    end
    v.reload
    assert_equal "newname", v.name
    assert_equal "newvalue", v.value
  end
end
