require 'test_helper'

if BigTuna::VCS::Mercurial.supported?

class MercurialVCSTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir repo; cd repo; hg init; echo "my file" > file; hg add file; hg commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
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

  test "hg head_info with other branches than default" do
    `cd test/files/repo; hg branch 'newbranch' 2>&1 > /dev/null; echo "new file" > new_file; hg add new_file; hg commit -m "new file in branch"; hg update default 2>&1 > /dev/null`
    vcs = init_repo("test/files/repo", "newbranch")
    info, _ = vcs.head_info
    assert_equal "new file in branch", info[:commit_message]
  end

  test "hg clone with other branches than default" do
    `cd test/files/repo; hg branch 'newbranch' 2>&1 > /dev/null; echo "new file" > new_file; hg add new_file; hg commit -m "new file in branch"; hg udpate default 2>&1 > /dev/null`
    vcs = init_repo("test/files/repo", "newbranch")
    vcs.clone("test/files/repo_clone")
    info, _ = vcs.head_info
    assert_equal "new file in branch", info[:commit_message]
    assert File.file?("test/files/repo_clone/new_file")
  end

  test "hg should support incremental_build" do
    vcs = init_repo
    assert vcs.support_incremental_build?
  end

  test "hg update should get commit in the clone" do
    vcs = init_repo
    vcs.clone("test/files/repo_clone")
    message = 'last commit message'
    assert_not_equal vcs.head_info[0][:commit_message], 'last commit message'
    `cd test/files/repo; echo "new file" > new_file; hg add new_file; hg commit -m "#{message}"`
    vcs.update("test/files/repo_clone")
    assert_equal vcs.head_info[0][:commit_message], 'last commit message'
    assert File.file?("test/files/repo_clone/new_file"), "The file has not been pulled"
  end

  private
  def init_repo(dir = "test/files/repo", branch = "default")
    BigTuna::VCS::Mercurial.new(dir, branch)
  end
end

end
