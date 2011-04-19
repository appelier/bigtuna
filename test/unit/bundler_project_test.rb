require 'test_helper'

class BundlerProjectTest < ActiveSupport::TestCase
  def setup
    super
    create_bundler_test_repo
  end

  def teardown
    destroy_test_repo
    super
  end

  test "bundler projects are auto-discovered" do
    project = project_with_steps({:name => "bundlerproject", :vcs_source => "test/files/bundler_repo", :vcs_type => "git"}, "env")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    envs = build.parts[0].output[0].stdout
    bundle_gemfile_env = envs.map! { |e| e.split("=") }.assoc("BUNDLE_GEMFILE")
    assert_equal File.join(build.build_dir, "Gemfile"), bundle_gemfile_env[1]
  end

  private
  def create_bundler_test_repo
    command = <<-CMD.gsub("\n", "; ")
      mkdir -p test/files/bundler_repo
      cd test/files/bundler_repo
      git init
      git config user.name git
      git config user.email git@example.com
      echo "my file" > file
      touch Gemfile
      git add file Gemfile
      git commit -m "bundler project added"
    CMD
    `#{command}`
  end

  def destroy_test_repo
    FileUtils.rm_rf 'test/files/bundler_repo'
  end
end
