class Build < ActiveRecord::Base
  STATUS_IN_QUEUE = "status_build_in_queue"
  STATUS_PROGRESS = "status_build_in_progress"
  STATUS_OK = "status_build_ok"
  STATUS_FAILED = "status_build_failed"
  belongs_to :project
  before_destroy :remove_build_dir
  before_create :set_build_values

  def perform
    self.update_attributes!(:status => STATUS_PROGRESS)
    stdout = ""
    self.started_at = Time.now
    stdout << Runner.execute("git clone #{project.vcs_source} #{self.build_dir} 2>&1")
    stdout << Runner.execute("cd #{self.build_dir} && #{project.task} 2>&1")
    status = $?.exitstatus
    self.stdout = stdout
    if status == 0
      self.status = STATUS_OK
    else
      self.status = STATUS_FAILED
    end
    self.save!
    project.truncate_builds!
  end

  def display_name
    commit[0, 7]
  end

  private
  def remove_build_dir
    FileUtils.rm_rf(self.build_dir) if File.directory?(self.build_dir)
  end

  def set_build_values
    project_dir = project.build_dir
    self.build_dir = File.join(project_dir, self.scheduled_at.strftime("%Y%m%d%H%M%S") + "_" + commit[0, 10])
    self.status = STATUS_IN_QUEUE
    self.scheduled_at = Time.now
  end
end
