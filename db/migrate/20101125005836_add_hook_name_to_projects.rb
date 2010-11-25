class AddHookNameToProjects < ActiveRecord::Migration
  def self.up
    add_column(:projects, :hook_name, :string)
  end

  def self.down
    remove_column(:projects, :hook_name)
  end
end
