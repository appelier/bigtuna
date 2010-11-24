class Project < ActiveRecord::Base
  has_many :builds

  def build!
    commit = `git log --format=oneline --max-count=1`.split(" ")[0]
    build = self.builds.create!(:commit => commit, :status => Build::STATUS_PROGRESS)
    Delayed::Job.enqueue(build)
  end

  def build_dir
    File.join("builds", name.downcase.gsub(/[^A-Za-z0-9]/, "_"))
  end
end
