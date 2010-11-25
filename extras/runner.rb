class Runner
  def self.execute(dir, command)
    Rails.logger.debug("[BigTuna] current dir: #{dir}")
    Rails.logger.debug("[BigTuna] executing: #{command}")
    Bundler.with_clean_env do
      Dir.chdir(dir) do
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
  end
end
