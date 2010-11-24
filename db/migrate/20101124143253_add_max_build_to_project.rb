class AddMaxBuildToProject < ActiveRecord::Migration
  def self.up
    add_column(:projects, :max_builds, :integer)
  end

  def self.down
    remove_column(:projects, :max_builds)
  end
end
