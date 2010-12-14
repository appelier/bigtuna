require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "build duration doesn't include minutes if less than minute" do
    time = Time.now
    build = Build.make(:started_at => time - 45, :finished_at => time)
    assert_equal "45s", build_duration(build)
  end

  test "build duration displays minutes if more than one" do
    time = Time.now
    build = Build.make(:started_at => time - (60 * 16 + 34), :finished_at => time)
    assert_equal "16m 34s", build_duration(build)
  end

  test "strip_shell_colorization removes shell colors" do
    text = "\e[32msome color \e[0mblah"
    stripped = strip_shell_colorization(text)
    assert_equal "some color blah", stripped
  end
end
