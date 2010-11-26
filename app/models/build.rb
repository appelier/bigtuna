class Build < ActiveRecord::Base
  STATUS_IN_QUEUE = "status_build_in_queue"
  STATUS_PROGRESS = "status_build_in_progress"
  STATUS_OK = "status_build_ok"
  STATUS_FAILED = "status_build_failed"
  STATUS_BUILDER_ERROR = "status_builder_error"

  belongs_to :project
  before_destroy :remove_build_dir
  before_create :set_build_values
  serialize :stdout, Array

  def perform
    self.update_attributes!(:status => STATUS_PROGRESS)
    self.started_at = Time.now
    status, output = execute_steps
    self.stdout = output
    self.status = status
    self.save!
    project.truncate_builds!
  rescue Exception
    self.status = STATUS_BUILDER_ERROR
    self.save!
  end

  def display_name
    commit[0, 7]
  end

  private
  def remove_build_dir
    if File.directory?(self.build_dir)
      FileUtils.rm_rf(self.build_dir)
    else
      Rails.logger.debug("[BigTuna] Couldn't find build dir: %p" % [self.build_dir])
    end
  end

  def set_build_values
    project_dir = project.build_dir
    self.build_dir = File.join(project_dir, self.scheduled_at.strftime("%Y%m%d%H%M%S") + "_" + commit[0, 7] + "_" + rand(32**8).to_s(36))
    self.status = STATUS_IN_QUEUE
    self.scheduled_at = Time.now
  end

  def execute_steps
    all_steps = [
      [Dir.pwd, "git clone #{project.vcs_source} #{self.build_dir} 2>&1"]
    ]
    project.steps.split("\n").each do |step|
      all_steps << [self.build_dir, "#{step} 2>&1"]
    end
    output = []
    exit_code = 0
    all_steps.each do |dir, command|
      begin
        output << {:command => command, :output => Runner.execute(dir, command)}
      rescue Runner::Error => e
        output << {:command => command, :output => e.output}
        exit_code = e.exit_code
        break
      end
    end
    status = exit_code == 0 ? STATUS_OK : STATUS_FAILED
    [status, output]
  end
end
