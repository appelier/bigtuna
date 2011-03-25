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
      return if txt.nil?
      @output << [TYPE_STDOUT, txt]
    end

    def append_stderr(txt)
      return if txt.nil?
      @output << [TYPE_STDERR, txt]
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
      convert_output
    end

    def has_output?
      @output.any?
    end

    private
    def convert_output
      
      grouped_by_type = @output.inject [] do |sofar, current|
        
        # start fresh if this is a new type of stream
        if sofar == [] || sofar.last[0] != current[0]
          sofar << current
        
        # or we just append the content
        else
          sofar.last[1] << current[1]
        end
        
        sofar
        
      end
      
      
      grouped_by_type.map! { |type, text| text.gsub("\r", "").split("\n").map { |line| [type, line] } }
      @output = []
      grouped_by_type.each { |entries| entries.each { |entry| @output << entry } }
      @output
    end
  end
end
