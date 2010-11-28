class CreateHooks < ActiveRecord::Migration
  def self.up
    create_table :hooks do |t|
      t.integer :project_id, :null => false
      t.string :hook_name, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :hooks
  end
end
