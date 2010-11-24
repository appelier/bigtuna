class AddBuildDirToBuilds < ActiveRecord::Migration
  def self.up
    add_column(:builds, :build_dir, :string)
  end

  def self.down
    remove_column(:builds, :build_dir)
  end
end
