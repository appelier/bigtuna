class AddPositionToProject < ActiveRecord::Migration
  def self.up
    add_column(:projects, :position, :integer)
  end

  def self.down
    remove_column(:projects, :position)
  end
end
