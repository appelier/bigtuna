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
      @output << [TYPE_STDOUT, txt.strip]
    end

    def append_stderr(txt)
      return if txt.nil?
      @output << [TYPE_STDERR, txt.strip]
    end

    def stdout
      out = @output.select { |e| e[0] == TYPE_STDOUT}.map { |e| e[1] }.join("\n")
      out = nil if out.blank?
      out
    end

    def stderr
      out = @output.select { |e| e[0] == TYPE_STDERR}.map { |e| e[1] }.join("\n")
      out = nil if out.blank?
      out
    end

    def to_s
      out = @output.map { |e| e[1] }.join("\n")
      out = nil if out.blank?
      out
    end

    def each
      @output.each { |type, out| yield type, out }
    end

    def ok?
      exit_code == 0
    end
  end
end
