class AddSharedVariablesToBuildPart < ActiveRecord::Migration
  def self.up
    add_column(:build_parts, :shared_variables, :text)
  end

  def self.down
    remove_column(:build_parts, :shared_variables)
  end
end
