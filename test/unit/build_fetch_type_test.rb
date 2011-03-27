require 'test_helper'
require 'mocha'

class BuildFetchTyeTest < ActiveSupport::TestCase
  
  def setup
    @vcs = mock_vcs
    @project = mock_project
    @build = mock_build
  end

  test 'if the project is clone, the build should always clone' do
    @project.fetch_type = :clone
    
    @vcs.expects(:clone).returns('cloned').once
    @vcs.expects(:update).returns('updated').never

    @build.perform
  end

  test 'if the project is incremental, the build shoud update ios clone' do
    @project.fetch_type = :incremental
    
    @vcs.expects(:update).returns('updated').once
    @vcs.expects(:clone).returns('cloned').never

    @build.perform
  end
  
  private
  
  def mock_vcs
    vcs = mocha
    vcs.stubs(:head_info).returns([{},nil])
    vcs
  end
  
  def mock_project
    project = project_with_steps({
      :name => "Atom project",
      :vcs_source => "no/such/repo",
    }, "echo 'ha'")
    
    project.stubs(:vcs).returns(@vcs)
    project
  end
  
  def mock_build
    build = Build.make(:project => @project)
    build.project = @project
    build.stubs(:vcs).returns(@vcs)
    build
  end
end