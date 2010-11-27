class AddFinishedAtToBuilds < ActiveRecord::Migration
  def self.up
    add_column(:builds, :finished_at, :datetime)
  end

  def self.down
    remove_column(:builds, :finished_at)
  end
end
