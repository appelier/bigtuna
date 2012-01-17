class OutputNeedsToBeLongtextWithMysql < ActiveRecord::Migration
  def self.up
    change_column :build_parts, :output, :longtext
    change_column :builds, :output, :longtext
  end

  def self.down
    change_column :build_parts, :output, :text
    change_column :builds, :output, :text
  end
end
