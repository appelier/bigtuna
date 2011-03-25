require 'test_helper'

class OutputTest < ActiveSupport::TestCase
  
  
  OUT = BigTuna::Runner::Output::TYPE_STDOUT
  ERR = BigTuna::Runner::Output::TYPE_STDERR
  
  
  setup do
    @output = BigTuna::Runner::Output.new 'test-dir', 'test-command'
  end
  
  
  test 'output is grouped' do
    
    @output.append_stdout 'a'
    @output.append_stdout 'b'
    @output.append_stderr 'c'
    
    result = @output.finish 0
    
    assert_equal result, [[OUT, 'ab'],[ERR,'c']]
    
  end
  
  
  test 'linebreaks are seperated' do
    
    @output.append_stdout "a\nb"
    @output.append_stderr 'c'
    
    result = @output.finish 0
    
    assert_equal result, [[OUT, 'a'],[OUT, 'b'],[ERR,'c']]
    
  end
  
  
  test 'trailing linebreaks are seperated' do
    
    @output.append_stdout "a\n"
    @output.append_stdout "b"
    @output.append_stderr 'c'
    
    result = @output.finish 0
    
    assert_equal result, [[OUT, 'a'],[OUT, 'b'],[ERR,'c']]
    
  end
  
  
end
