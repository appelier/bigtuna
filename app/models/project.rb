class Project < ActiveRecord::Base
  STATUS_NOT_BUILT = "status_not_built"

  has_many :builds, :dependent => :destroy
  before_destroy :remove_build_folder

  acts_as_list

  def recent_build
    builds.order("created_at DESC").first
  end

  def build!
    commit_info = `cd #{self.vcs_source}; git log --max-count=1 --format="%H%n%an%n%ae%n%ad%n%s"`.split("\n")
    commit_hash = commit_info.shift
    author = commit_info.shift
    email = commit_info.shift
    date = Time.parse(commit_info.shift)
    message = commit_info.join("\n")
    build = self.builds.create!(:commit => commit_hash,
                                :author => author,
                                :email => email,
                                :committed_at => date,
                                :commit_message => message,
                                :scheduled_at => Time.now)
    Delayed::Job.enqueue(build)
  end

  def build_dir
    File.join("builds", name.downcase.gsub(/[^A-Za-z0-9]/, "_"))
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

  private
  def remove_build_folder
    if File.directory?(self.build_dir)
      FileUtils.rm_rf(self.build_dir)
    else
      Rails.logger.debug("[BigTuna] Couldn't find build dir: %p" % [self.build_dir])
    end
  end
end
