require_relative 'test_helper'
require 'parametric/tools'

module Parametric
  class TC_Tools < TestUp::TestCase
    def test_default
      subject = Tools
      tool = 'some_tool'
      subject.set_default :push_pull, tool
      assert_equal tool, subject.default(:push_pull)
    end
  end
end
