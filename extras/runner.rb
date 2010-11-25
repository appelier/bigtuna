class Runner
  def self.execute(dir, command)
    Rails.logger.debug("[BigTuna] executing in #{dir}: #{command}")
    with_clean_env do
      buffer = []
      Dir.chdir(dir) do
        IO.popen(command) do |io|
          io.each_line do |line|
            buffer << line
          end
        end
      end

      status = $?.exitstatus
      output = buffer.join("\n")
      Rails.logger.debug("[BigTuna] output: #{output}")
      Rails.logger.debug("[BigTuna] exit status: #{status}")
      output
    end
  end

  def self.with_clean_env(&blk)
    old_env = ENV.clone
    ENV.delete("BUNDLE_GEMFILE")
    ENV["BUNDLE_APP_CONFIG"] = Dir.pwd + "/.bundle/config"
    ENV["PWD"] = Dir.pwd
    result = blk.call
    result
  ensure
    old_env.each do |key, value|
      ENV[key] = value
    end
  end
end
