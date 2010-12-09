class AddHookDisablingConfiguration < ActiveRecord::Migration
  def self.up
    add_column(:hooks, :hooks_enabled, :text)
  end

  def self.down
    remove_column(:hooks, :hooks_enabled)
  end
end
