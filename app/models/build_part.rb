class BuildPart < ActiveRecord::Base
  STATUS_OK = "status_build_part_ok"
  STATUS_FAILED = "status_build_part_failed"
  STATUS_IN_QUEUE = "status_build_part_in_queue"
  STATUS_PROGRESS = "status_build_part_in_progress"

  belongs_to :build

  before_create :set_build_values
  serialize :output, Array
  serialize :shared_variables, Hash

  def build!
    self.update_attributes!(:status => STATUS_IN_QUEUE)
    Delayed::Job.enqueue(self)
  end

  def perform
    self.update_attributes!(:status => STATUS_PROGRESS, :started_at => Time.now)
    all_steps = []
    steps.split("\n").each do |step|
      step = format_step_command(step)
      all_steps << [self.build_dir, step] unless step.empty?
    end
    exit_code = 0
    all_steps.each_with_index do |step, index|
      dir, command = step
      begin
        out = BigTuna::Runner.execute(dir, command)
        self.output << out
        self.save!
      rescue BigTuna::Runner::Error => e
        output << e.output
        exit_code = e.output.exit_code
        break
      end
    end
    self.status = exit_code == 0 ? STATUS_OK : STATUS_FAILED
    all_steps[output.size .. -1].each do |dir, command|
      self.output << BigTuna::Runner::Output.new(dir, command)
    end
    save!
  ensure
    self.update_attributes!(:finished_at => Time.now)
    build.update_part(self)
  end

  def build_dir
    build.build_dir
  end

  private
  def format_step_command(cmd)
    new_cmd = cmd.dup
    keys = shared_variables.keys
    keys.reject! { |key| key == "project_dir" || key == "build_dir" }
    keys.push("project_dir")
    keys.push("build_dir")
    # order is important, so that we can use %project_dir% in custom variables
    keys.each do |var_name|
      var_value = shared_variables[var_name]
      new_cmd.gsub!("%#{var_name}%", var_value)
    end
    comment_at = new_cmd.index("#")
    new_cmd = new_cmd[0...comment_at] unless comment_at.nil?
    new_cmd.strip!
    new_cmd
  end

  def set_build_values
    self.output = []
  end
end
