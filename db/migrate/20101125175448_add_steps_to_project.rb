class AddStepsToProject < ActiveRecord::Migration
  def self.up
    remove_column(:projects, :task)
    add_column(:projects, :steps, :text)
  end

  def self.down
    remove_column(:projects, :steps)
    add_column(:projects, :task, :string)
  end
end
