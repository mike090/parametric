require 'testup/testcase'
require_relative '../src/parametric/tools'

class TC_Tools < TestUp::TestCase
  def test_default
    subject = Parametric::Tools
    tool = 'some_tool'
    subject.set_default :push_pull, tool
    assert_equal tool, subject.default(:push_pull)
  end
end
