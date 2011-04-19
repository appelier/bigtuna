require 'test_helper'

if BigTuna::VCS::Git.supported?

class GitVCSTest < ActiveSupport::TestCase

  include WithTestRepo

  def teardown
    FileUtils.rm_rf("test/files/repo_clone")
    super
  end

  test "head_info returns commit information" do
    vcs = init_repo
    info, _ = vcs.head_info
    assert info.has_key?(:commit)
    assert info.has_key?(:author)
    assert info.has_key?(:email)
    assert info.has_key?(:committed_at)
    assert info.has_key?(:commit_message)
    assert_equal "my file added", info[:commit_message]
  end

  test "clone clones the repo" do
    vcs = init_repo
    vcs.clone("test/files/repo_clone")
    vcs_clone = init_repo("test/files/repo_clone")
    assert_equal vcs.head_info[0], vcs_clone.head_info[0]
  end

  test "git head_info with other branches than master" do
    `cd test/files/repo; git checkout -b 'newbranch' 2>&1 > /dev/null; echo "new file" > new_file; git add new_file; git commit -m "new file in branch"; git checkout master 2>&1 > /dev/null`
    vcs = init_repo("test/files/repo", "newbranch")
    info, _ = vcs.head_info
    assert_equal "new file in branch", info[:commit_message]
  end

  test "git clone with other branches than master" do
    `cd test/files/repo; git checkout -b 'newbranch' 2>&1 > /dev/null; echo "new file" > new_file; git add new_file; git commit -m "new file in branch"; git checkout master 2>&1 > /dev/null`
    vcs = init_repo("test/files/repo", "newbranch")
    vcs.clone("test/files/repo_clone")
    info, _ = vcs.head_info
    assert_equal "new file in branch", info[:commit_message]
    assert File.file?("test/files/repo_clone/new_file")
  end

  test "git should support incremental_build" do
    vcs = init_repo

    assert vcs.support_incremental_build?
  end
  
  test "git update should get commit in the clone" do
    `cd test/files/repo; echo "new file" > new_file; git add new_file; git commit -m "new file"`
    vcs = init_repo("test/files/repo", "master")
    vcs.clone("test/files/repo_clone")
    
    `cd test/files/repo; echo "new file" > new_file_2; git add new_file_2; git commit -m "new second file"`
    vcs.update("test/files/repo_clone")
    
    assert File.file?("test/files/repo_clone/new_file_2"), "The file has not been pulled"
  end
  
  private
  def init_repo(dir = "test/files/repo", branch = "master")
    BigTuna::VCS::Git.new(dir, branch)
  end
end

end
