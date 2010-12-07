class CreateBuildParts < ActiveRecord::Migration
  def self.up
    create_table :build_parts do |t|
      t.integer :build_id, :null => false
      t.string :name
      t.text :steps
      t.text :output
      t.string :status
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamps
    end
  end

  def self.down
    drop_table :build_parts
  end
end
