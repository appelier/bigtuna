class AddBranchToProject < ActiveRecord::Migration
  def self.up
    add_column(:projects, :vcs_branch, :string)
  end

  def self.down
    remove_column(:projects, :vcs_branch)
  end
end
