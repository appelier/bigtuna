class Build < ActiveRecord::Base
  STATUS_PROGRESS = "progress"
  STATUS_OK = "ok"
  STATUS_FAILED = "failed"
  belongs_to :project
  after_destroy :remove_build_dir

  def perform
    project_dir = project.build_dir
    self.build_dir = File.join(project_dir, Time.now.strftime("%Y%m%d%H%M%S") + "_" + commit)
    command = "git clone #{project.vcs_source} \"#{self.build_dir}\""
    `#{command}`
    self.stdout = `cd #{self.build_dir} && rake 2>&1 | tee rake.log`
    status = $?.exitstatus
    if status == 0
      self.status = STATUS_OK
    else
      self.status = STATUS_FAILED
    end
    self.save!
    project.truncate_builds!
  end

  private
  def remove_build_dir
    FileUtils.rm_rf(self.build_dir)
  end
end
