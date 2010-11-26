class Project < ActiveRecord::Base
  STATUS_NOT_BUILT = "status_not_built"

  has_many :builds, :dependent => :destroy
  before_destroy :remove_build_folder

  acts_as_list

  def recent_build
    builds.order("created_at DESC").first
  end

  def build!
    head_info, head_command = vcs.head_info
    build = self.builds.create!(head_info.merge(:scheduled_at => Time.now))
    Delayed::Job.enqueue(build)
  end

  def build_dir
    File.join(Rails.root, "builds", name.downcase.gsub(/[^A-Za-z0-9]/, "_"))
  end

  def truncate_builds!
    builds.order("created_at DESC").offset(self.max_builds).each do |build|
      build.destroy
    end
  end

  def max_builds
    super || 10
  end

  def status
    build = recent_build
    build.nil? ? STATUS_NOT_BUILT : build.status
  end

  def vcs
    return @vcs if @vcs
    case vcs_type
    when "git"
      @vcs = VCS::Git.new(self.vcs_source)
    else
      raise ArgumentError.new("VCS not supported: %p" % [vcs_type])
    end
  end

  private
  def remove_build_folder
    if File.directory?(self.build_dir)
      FileUtils.rm_rf(self.build_dir)
    else
      Rails.logger.debug("[BigTuna] Couldn't find build dir: %p" % [self.build_dir])
    end
  end
end
