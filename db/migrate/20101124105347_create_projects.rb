class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name, :null => false
      t.string :vcs_type, :null => false
      t.string :vcs_source, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
