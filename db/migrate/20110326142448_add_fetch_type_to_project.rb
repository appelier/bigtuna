class AddFetchTypeToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :fetch_type, :string, :default => :clone
  end

  def self.down
    remove_column :projects, :fetch_type
  end
end
