class Runner
  def self.execute(dir, command)
    end_command = "cd #{dir} 2>&1 && #{command} 2>&1"
    Rails.logger.debug("[BigTuna] executing: #{end_command}")
    with_clean_env(dir) do
      buffer = []
      IO.popen(end_command) do |io|
        io.each_line do |line|
          buffer << line.strip
        end
      end
      status = $?.exitstatus
      output = buffer.join("\n")
      output = nil if output.strip.blank?
      Rails.logger.debug("[BigTuna] output: #{output}")
      Rails.logger.debug("[BigTuna] exit status: #{status}")
      raise Runner::Error.new(dir, command, status, output) if status != 0
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
    attr_reader :exit_code, :output

    def initialize(dir, command, exit_code, output)
      @dir, @command, @exit_code, @output = dir, command, exit_code, output
    end

    def message
      "Error (#{@exit_code}) executing '#{@command}' in '#{@dir}' #{@output}"
    end
  end
end
