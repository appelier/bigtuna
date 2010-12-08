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
    super
  end

  test "hooks config renders hook config partial if it's present" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/repo",
      :max_builds => 2,
      :hooks => {"mailer" => "mailer"},
    }, "ls")
    visit edit_project_path(project)
    within("#hook_mailer") do
      click_link "Configure"
    end
    assert page.has_content?("Recipients")
  end

  test "hooks with no config print out this info to user" do
    with_hook_enabled(BigTuna::Hooks::NoConfig) do
      project = project_with_steps({
        :name => "Koss",
        :vcs_source => "test/files/repo",
        :max_builds => 2,
        :hooks => {"no_config" => "no_config"},
      }, "ls")
      visit edit_project_path(project)
      within("#hook_no_config") do
        click_link "Configure"
      end
      assert page.has_content?("This hook doesn't have any configuration.")
    end
  end

  test "xmpp hook has a valid configuration form" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/repo",
      :max_builds => 2,
      :hooks => {"xmpp" => "xmpp"},
    }, "ls")

    visit edit_project_path(project)
    within("#hook_xmpp") do
      click_link "Configure"
    end
    assert page.has_field?("configuration_sender_full_jid")
    assert page.has_field?("configuration_sender_password")
    assert page.has_field?("configuration_recipients")
    click_button "Edit"
    assert_status_code 200
  end
end