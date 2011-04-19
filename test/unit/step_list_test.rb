class StepListTest < ActiveSupport::TestCase
  test "steps cant be blank" do
    assert_invalid(StepList, :steps) { |p| p.steps = "" }
  end

  test "steps cant be whitespace only" do
    assert_invalid(StepList, :steps) { |p| p.steps = "     " }
  end

  test "steps cant be comments only" do
    assert_invalid(StepList, :steps) { |p| p.steps = "#invalid" }
    assert_invalid(StepList, :steps) { |p| p.steps = "#invalid\n#invalid2" }
  end
end
