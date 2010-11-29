class RenameStdoutToOutput < ActiveRecord::Migration
  def self.up
    rename_column(:builds, :stdout, :output)
  end

  def self.down
    rename_column(:builds, :output, :stdout)
  end
end
