class Build < ActiveRecord::Base
  STATUS_PROGRESS = "progress"
  STATUS_OK = "ok"
  STATUS_FAILED = "failed"
  belongs_to :project
  after_destroy :remove_build_dir

  def perform
    project_dir = project.build_dir
    self.started_at = Time.now
    self.build_dir = File.join(project_dir, self.scheduled_at.strftime("%Y%m%d%H%M%S") + "_" + commit[0, 10])
    command = "git clone #{project.vcs_source} \"#{self.build_dir}\""
    Rails.logger.debug("BigTuna executing: #{command}")
    `#{command}`
    command = "cd #{self.build_dir} && #{project.task} 2>&1 | tee big_tuna.log"
    Rails.logger.debug("BigTuna executing: #{command}")
    self.stdout = `#{command}`
    status = $?.exitstatus
    if status == 0
      self.status = STATUS_OK
    else
      self.status = STATUS_FAILED
    end
    self.save!
    project.truncate_builds!
  end

  def display_name
    "#{commit[0, 10]} @ #{self.scheduled_at.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  private
  def remove_build_dir
    FileUtils.rm_rf(self.build_dir)
  end
end
