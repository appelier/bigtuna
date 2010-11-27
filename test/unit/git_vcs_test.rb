require 'test_helper'

class GitVCSTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("test/files/repo_bare")
    FileUtils.rm_rf("test/files/repo_clone")
    super
  end

  test "valid? returns true if repo exists" do
    vcs = init_repo
    assert vcs.valid?
  end

  test "valid? returns true if bare repo exists" do
    `cd test/files; mkdir repo_bare; git --bare init`
    vcs = init_repo("test/files/repo_bare")
    assert vcs.valid?
  end

  test "cannot instantiate without valid repo" do
    assert_raises(VCS::Error) do
      init_repo("/not/a/repo")
    end
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

  private
  def init_repo(dir = "test/files/repo")
    VCS::Git.new(dir)
  end
end
