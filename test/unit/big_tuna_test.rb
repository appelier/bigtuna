require 'test_helper'

class BigTunaTest < ActiveSupport::TestCase
  test "BigTuna creates the build directory" do
    if File.directory?(File.join(Rails.root.to_s, BigTuna.build_dir))
      FileUtils.rm_rf(File.join(Rails.root.to_s, BigTuna.build_dir))
    end
    assert_difference("Dir[File.join(Rails.root.to_s, '*')].size", 1) do
      BigTuna.create_build_dir
    end
  end

  test "BigTuna's build directory has proper permissions" do
    BigTuna.create_build_dir
    # Check if the permission is actually 0754
    assert_equal 492, File.stat(File.join(Rails.root.to_s, BigTuna.build_dir)).mode & 0777
  end
end
