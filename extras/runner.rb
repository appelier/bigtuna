class Runner
  def self.execute(dir, command)
    end_command = "cd #{dir} && #{command}"
    Rails.logger.debug("[BigTuna] executing: #{end_command}")
    with_clean_env(dir) do
      output = Runner::Output.new(dir, command)
      buffer = []
      status = Open4.popen4(end_command) do |_, _, stdout, stderr|
        while !stdout.eof? or !stderr.eof?
          output.append_stderr(stderr.gets)
          output.append_stdout(stdout.gets)
        end
      end
      output.exit_code = status.exitstatus
      Rails.logger.debug("[BigTuna] exit code: #{output.exit_code}")
      raise Runner::Error.new(output) if output.exit_code != 0
      output
    end
  end

  def self.with_clean_env(dir, &blk)
    old_env = ENV.clone
    ENV.clear
    ORIGINAL_ENV.each { |key, value| ENV[key] = value }
    ENV["RAILS_ENV"] = "test"
    result = blk.call
    result
  ensure
    ENV.clear
    old_env.each do |key, value|
      ENV[key] = value
    end
  end

  class Error < Exception
    attr_reader :output

    def initialize(output)
      @output = output
    end

    def message
      "Error (#{@output.exit_code}) executing '#{@output.command}' in '#{@output.dir}'"
    end
  end
end
