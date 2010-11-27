class AddMailRecipientsToProject < ActiveRecord::Migration
  def self.up
    add_column(:projects, :recipients, :string)
  end

  def self.down
    remove_column(:projects, :recipients)
  end
end
