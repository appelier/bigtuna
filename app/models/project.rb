class Project < ActiveRecord::Base
  has_many :builds

  def build!
    commit = `git log --format=oneline --max-count=1`.split(" ")[0]
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
end
