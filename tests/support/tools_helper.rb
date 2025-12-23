require 'minitest/mock'

module Parametric
  module Tools
    module Helpers
      def mock_tool(retval, *expected)
        MockTool.new(retval, *expected)
      end

      def tool_fixture(tool, &init_block)
        Class.new.include(TestFixture, tool).new(&init_block)
      end

      class MockTool
        extend Forwardable
        def_delegator :@mock, :verify, :used?

        attr_accessor :expected_params, :retval

        def initialize(retval, *expected_stage_params)
          @retval = retval
          @expected = expected_stage_params
        end

        def as_stage(*stage_params, &block)
          @stage_params = stage_params
          @callback = block
          @mock = MiniTest::Mock.new.expect :activate, @retval, @expected
          self
        end

        def activate
          @callback&.call @mock.activate(*@stage_params)
        end

        def skipped?
          @mock.verify
          false
        rescue MockExpectationError
          true
        end

        def unused?
          !instance_variable_defined?(:@mock)
        end
      end

      module TestFixture

        def initialize(&block)
          self.instance_eval &block if block
        end

        def done(*args)
          @when_done&.call(*args)
        end

        def when_done(&block)
          @when_done = block
          self
        end
      end      
    end
  end
end
