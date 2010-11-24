class Project < ActiveRecord::Base
  STATUS_NOT_BUILT = "status_not_built"
  has_many :builds

  def recent_build
    builds.order("created_at DESC").first
  end

  def build!
    commit = `cd #{self.vcs_source}; git log --format=oneline --max-count=1`.split(" ")[0]
    build = self.builds.create!(:commit => commit, :status => Build::STATUS_PROGRESS, :scheduled_at => Time.now)
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
end
