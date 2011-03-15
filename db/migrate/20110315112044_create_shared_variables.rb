class CreateSharedVariables < ActiveRecord::Migration
  def self.up
    create_table :shared_variables do |t|
      t.integer :step_list_id
      t.string :name
      t.string :value
      t.timestamps
    end
  end

  def self.down
    drop_table :shared_variables
  end
end
