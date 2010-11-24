class CreateBuilds < ActiveRecord::Migration
  def self.up
    create_table :builds do |t|
      t.references :project
      t.string :commit
      t.string :status
      t.text :stdout
      t.timestamps
    end
  end

  def self.down
    drop_table :builds
  end
end
