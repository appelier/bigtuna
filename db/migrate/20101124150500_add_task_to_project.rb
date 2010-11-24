class AddTaskToProject < ActiveRecord::Migration
  def self.up
    add_column(:projects, :task, :string)
  end

  def self.down
    remove_column(:projects, :task)
  end
end
