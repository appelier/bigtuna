module ApplicationHelper
  def strip_rails_root(dir)
    ret = dir.gsub(Rails.root, "")
    ret = ret[1 .. -1] if ret =~ Regexp.new("^/")
    ret
  end

  def build_duration(build)
    seconds = (build.finished_at - build.started_at).to_i
    minutes = seconds / 60
    seconds = seconds - minutes * 60
    if minutes == 0
      "%ds" % [seconds]
    else
      "%dm %ds" % [minutes, seconds]
    end
  end

  def format_stability(stability)
    return "not yet built" if stability.nil?
    "%.2f%%" % [100.0 * stability]
  end
end
