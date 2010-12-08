class CreateStepLists < ActiveRecord::Migration
  def self.up
    create_table :step_lists do |t|
      t.string :name
      t.text :steps
      t.integer :project_id, :null => false
      t.timestamps
    end
    remove_column(:projects, :steps)
  end

  def self.down
    drop_table :step_lists
    add_column(:projects, :steps, :text)
  end
end
