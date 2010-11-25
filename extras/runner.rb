class Runner
  def self.execute(command)
    Rails.logger.debug("[BigTuna] executing: #{command}")
    with_clean_env do
      buffer = []
      IO.popen(command) do |io|
        io.each_line do |line|
          buffer << line
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
    ENV["PWD"] = Dir.pwd
    result = blk.call
    ENV["BUNDLE_GEMFILE"] = old_env["BUNDLE_GEMFILE"]
    ENV["PWD"] = old_env["PWD"]
    result
  end
end
