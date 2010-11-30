require "integration_test_helper"

module BigTuna
  class Hooks::NoConfig
    NAME = "no_config"
  end
end

class HooksTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    FileUtils.rm_rf("builds/*")
    super
  end

  test "hooks config renders hook config partial if it's present" do
    project = Project.make(:steps => "ls", :name => "Koss", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 2, :hooks => {"mailer" => "mailer"}, :hook_update => true)
    visit edit_project_path(project)
    within("#hook_mailer") do
      click_link "Configure"
    end
    assert page.has_content?("Recipients")
  end

  test "hooks with no config print out this info to user" do
    with_hook_enabled(BigTuna::Hooks::NoConfig) do
      project = Project.make(:steps => "ls", :name => "Koss", :vcs_source => "test/files/repo", :vcs_type => "git", :max_builds => 2, :hooks => {"no_config" => "no_config"}, :hook_update => true)
      visit edit_project_path(project)
      within("#hook_no_config") do
        click_link "Configure"
      end
      assert page.has_content?("This hook doesn't have any configuration.")
    end
  end

  private
  def with_hook_enabled(hook, &blk)
    old_hooks = BigTuna::HOOKS.clone
    Kernel.silence_stream(STDERR) do
      BigTuna.const_set("HOOKS", old_hooks + [hook])
    end
    blk.call
  ensure
    Kernel.silence_stream(STDERR) do
      BigTuna.const_set("HOOKS", old_hooks)
    end
  end
end
