class AddStatsToProjects < ActiveRecord::Migration
  def self.up
    add_column(:projects, :total_builds, :integer)
    add_column(:projects, :failed_builds, :integer)
    add_column(:builds, :build_no, :integer)
  end

  def self.down
    remove_column(:projects, :total_builds)
    remove_column(:projects, :failed_builds)
    remove_column(:builds, :build_no)
  end
end
