class AddCommitFieldsToBuild < ActiveRecord::Migration
  def self.up
    add_column(:builds, :author, :string)
    add_column(:builds, :email, :string)
    add_column(:builds, :committed_at, :timestamp)
    add_column(:builds, :commit_message, :text)
  end

  def self.down
    remove_column(:builds, :author)
    remove_column(:builds, :email)
    remove_column(:builds, :committed_at)
    remove_column(:builds, :commit_message)
  end
end
