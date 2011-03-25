module BigTuna
  class Runner::Output
    TYPE_STDOUT = "stdout"
    TYPE_STDERR = "stderr"

    attr_reader :dir, :command
    attr_accessor :exit_code

    def initialize(dir, command)
      @dir, @command = dir, command
      @output = []
    end

    def append_stdout(txt)
      append TYPE_STDOUT, txt
    end

    def append_stderr(txt)
      append TYPE_STDERR, txt
    end

    def stdout
      @output.select { |e| e[0] == TYPE_STDOUT}.map { |e| e[1] }
    end

    def stderr
      @output.select { |e| e[0] == TYPE_STDERR}.map { |e| e[1] }
    end

    def all
      @output
    end

    def ok?
      exit_code == 0
    end

    def finish(exit_code)
      self.exit_code = exit_code
      @output
    end

    def has_output?
      @output.any?
    end

    private
    
    def append stream, txt
      
      return if txt.nil?
      
      lines = txt.split /\r?\n/, -1
      
      # continue from where we left off?
      unless @output.empty? || @output.last[0] != stream
        @output.last[1] << lines.shift
      end
      
      lines.each do |line|
        @output << [stream,line]
      end
      
    end
    
  end
end
