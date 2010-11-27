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
    status, output = execute_steps()
    self.stdout = output
    self.status = status
    project = self.project
    send_email_info() unless project.recipients.blank?
    self.save!
    project.truncate_builds!
  rescue Exception => e
    Rails.logger.warn("[BigTuna] Exception in build runner")
    Rails.logger.warn("[BigTuna] #{e.message}")
    Rails.logger.warn("[BigTuna] #{e.backtrace.join}")
    out = Runner::Output.new(Dir.pwd, "builder error")
    out.append_stdout(e.message)
    e.backtrace.each { |line| out.append_stdout(line) }
    out.exit_code = 1
    self.stdout = [out]
    self.status = STATUS_BUILDER_ERROR
    self.save!
  end

  def display_name
    commit[0, 7]
  end

  def to_param
    [self.id, self.project.name.to_url, self.display_name.to_url].join("-")
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
      [Dir.pwd, lambda { project.vcs.clone(self.build_dir) }]
    ]
    project.steps.split("\n").each do |step|
      step = process_step_command(step)
      all_steps << [self.build_dir, step]
    end
    output = []
    exit_code = 0
    all_steps.each do |dir, command|
      begin
        if command.is_a?(Proc)
          out, command = command.call
        else
          out = Runner.execute(dir, command)
        end
        output << out
      rescue Runner::Error => e
        output << e.output
        exit_code = e.output.exit_code
        break
      end
    end
    all_steps[output.size .. -1].each do |dir, command|
      output << Runner::Output.new(dir, command)
    end
    status = exit_code == 0 ? STATUS_OK : STATUS_FAILED
    [status, output]
  end

  def process_step_command(cmd)
    cmd.gsub!("%build_dir%", self.build_dir)
    cmd.gsub!("%project_dir%", self.project.build_dir)
    cmd.strip!
    cmd
  end

  def send_email_info
    previous_build = self.project.builds.order("created_at DESC").offset(1).first
    if status == STATUS_OK && previous_build && previous_build.status == STATUS_FAILED
      GlobalMailer.delay.build_fixed(self)
    elsif status == STATUS_FAILED
      if previous_build.nil? or (previous_build && previous_build.status == STATUS_OK)
        GlobalMailer.delay.build_failed(self)
      else
        GlobalMailer.delay.build_still_fails(self)
      end
    end
  end
end
