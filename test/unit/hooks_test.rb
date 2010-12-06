require 'test_helper'

module BigTuna
  class Hooks::RaisingHook
    NAME = "raising_hook"

    def build_failed(build, config); raise "build_failed"; end
    def build_finished(build, config); raise "build_finished"; end
  end
end

class HooksUnitTest < ActiveSupport::TestCase
  def setup
    super
    `cd test/files; mkdir koss; cd koss; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/koss")
    FileUtils.rm_rf("builds/*")
    super
  end

  test "if hook produces error it is handled and marks build as hook failed" do
    with_hook_enabled(BigTuna::Hooks::RaisingHook) do
      project = Project.make({
        :steps => "nosuchstep",
        :name => "Koss",
        :vcs_source => "test/files/repo",
        :vcs_type => "git",
        :max_builds => 2,
        :hooks => {"raising_hook" => "raising_hook"},
        :hook_update => true,
      })

      job = project.build!
      job.invoke_job
      build = project.recent_build
      assert_equal Build::STATUS_HOOK_ERROR, build.status
    end
  end
end
