require 'test_helper'

class ProjectFetchTypeTest < ActiveSupport::TestCase
  
  def setup 
    super  
    @project = project_with_steps({
      :name => "Atom project",
      :vcs_source => "no/such/repo",
    }, "echo 'ha'")
  end
  
  def teardown
    super
    @project.destroy if @project
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
  
  test 'should validate a incremental build project if the vcs supports it' do
    vcs = mocha
    vcs.expects(:support_incremental_build?).returns(true)
    @project.expects(:vcs).returns(vcs)
    @project.fetch_type = :incremental

    assert @project.valid?
  end
  
  test 'should not validate a incremental build project if the vcs does not support it' do
    vcs = mocha
    vcs.expects(:support_incremental_build?).returns(false)
    @project.expects(:vcs).returns(vcs)
    @project.fetch_type = :incremental

    assert !@project.valid?
  end
    
end