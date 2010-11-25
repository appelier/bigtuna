class Runner
  def self.execute(dir, command)
    end_command = "cd #{dir}; #{command}"
    Rails.logger.debug("[BigTuna] executing: #{end_command}")
    with_clean_env(dir) do
      buffer = []
      IO.popen(end_command) do |io|
        io.each_line do |line|
          buffer << line
        end
        status = $?.exitstatus
        output = buffer.join("\n")
        Rails.logger.debug("[BigTuna] output: #{output}")
        Rails.logger.debug("[BigTuna] exit status: #{status}")
        output
      end
    end
  end

  def self.with_clean_env(dir, &blk)
    old_env = ENV.clone
    ENV.clear
    ORIGINAL_ENV.each { |key, value| ENV[key] = value }
    result = blk.call
    result
  ensure
    ENV.clear
    old_env.each do |key, value|
      ENV[key] = value
    end
  end
end
