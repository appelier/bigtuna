class AddStartedAtToBuild < ActiveRecord::Migration
  def self.up
    add_column(:builds, :started_at, :timestamp)
    add_column(:builds, :scheduled_at, :timestamp)
  end

  def self.down
    remove_column(:builds, :started_at)
    remove_column(:builds, :scheduled_at)
  end
end
