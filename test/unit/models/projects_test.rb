require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  
  def setup
    Project.destroy_all
    
    @project = project_with_steps({
      :name => "Atom project",
      :vcs_source => "no/such/repo",
    }, "echo 'ha'")
  end
  
  test 'by default a project should build by cloning' do
    @project.save!
    
    assert_equal :clone, @project.fetch_type, 'by default a project should build by cloning'
  end
  
  test 'should persist the fetch_type' do
    @project.fetch_type = :incremental
    @project.save!
    
    assert_equal :incremental, @project.fetch_type, 'should persist the fetch_type'
  end
  
end