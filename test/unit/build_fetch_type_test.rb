require 'test_helper'

class BuildFetchTyeTest < ActiveSupport::TestCase
  
  def setup
    super
    @project = project_with_steps({
      :name => "Atom project",
      :vcs_source => "no/such/repo",
    }, "echo 'ha'")
    @project.save!
  end
  
  def teardown
    super
    @project.destroy
  end
  
  test 'when the project fetch incrementally, the build_dir should be fixed' do
    @project.fetch_type = :incremental
    build = Build.make(:project => @project)
    
    assert_equal "#{@project.build_dir}/checkout", build.build_dir, 'the build_dir should be fix'
  end
  
end