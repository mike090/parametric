require_relative '../test_helper'
require_relative '../support/tools_helper'

module Parametric
  module Tools
    module Tests
      class TC_Helpers < TestUp::TestCase
        include Helpers

        def test_mock_tool
          block = MiniTest::Mock.new.expect(:call, nil, [4])
          sum_tool = mock_tool(4, 2, 2) # tool receive 2 & 2 and passes 4 to the block
          assert sum_tool.unused?
          stage = sum_tool.as_stage(2, 2) { |sum| block.call(sum) }
          refute sum_tool.unused?
          assert sum_tool.skipped?
          stage.activate
          assert stage.used?
          assert block.verify
        end

        module FakeTool
          def activate
            done @result
          end

          def done(result)
            raise NotImplementedError, 'heritors responsibility'
          end
        end

        def test_fixture
          done_flag = Minitest::Mock.new.expect(:raise,nil,['foo'])
          subject = tool_fixture(FakeTool) { @result = 'foo' }
          subject.when_done { |params| done_flag.raise *params }
          subject.activate
          assert done_flag.verify
        end
      end  
    end
  end
end