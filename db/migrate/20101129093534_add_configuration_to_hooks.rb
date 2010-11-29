class AddConfigurationToHooks < ActiveRecord::Migration
  def self.up
    add_column(:hooks, :configuration, :text)
    remove_column(:projects, :recipients)
  end

  def self.down
    remove_column(:hooks, :configuration)
    add_column(:projects, :recipients, :text)
  end
end
