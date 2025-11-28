require "testup/testcase"
require_relative '../../src/parametric/tools'
require_relative '../../src/parametric/tools/box_tool'
require 'forwardable'

class TC_BoxTool < TestUp::TestCase

  class MockTool

    extend Forwardable
    def_delegator :@mock, :verify, :used?
    
    def initialize(retval, *expected_params)
      @mock = MiniTest::Mock.new
      @mock.expect :perform, retval, expected_params  
    end

    def as_stage(*params, &block)
      block.call @mock.perform(*params)
    end

    def skipped?
      @mock.verify
      false
    rescue MockExpectationError
      true
    end

    alias unused? skipped?
  end

  def mock_block(retval,*expected_params)
    block = MiniTest::Mock.new
    block.expect(:call, retval, expected_params)
    block
  end

  def test_mock_tool
    expected_params = [2]
    retval = 4
    x2_tool = MockTool.new retval, *expected_params # tool receive 2 and passes 4 to the block 
    block = mock_block(true, 4)
    assert x2_tool.unused?
    assert x2_tool.as_stage(2) { |params| block.call(*params) }
    assert x2_tool.used?
    assert block.verify
  end

  def test_push_pull_skipped
    vectors = [10,20,30].each_with_index.map { |len, index| Geom::Vector3d.new [0,0].insert(index, len) }
    box_params = [ORIGIN, vectors]
    profile = [[0,0], [10,0], [10,20], [0,20]].map { |pos| Geom::Point3d.new pos }
    push_pull_vector = Geom::Vector3d.new 0,0,30
    xyz_tool = MockTool.new box_params, IDENTITY # gets nothing, returns box_params
    push_pull_tool = MockTool.new push_pull_vector, profile # gets rectangle, returns 3rd vector
    Parametric::Tools.set_default :xyz_tool, xyz_tool
    Parametric::Tools.set_default :push_pull_tool, push_pull_tool 
    subject = mock_block(nil, *box_params)
    Parametric::Tools::BoxTool.as_stage { |point, vectors| subject.call(point, vectors) }
    assert xyz_tool.used?
    assert push_pull_tool.skipped?
    assert subject.verify
  end

  def test_push_pull_used
    vectors = [10,20].each_with_index.map { |len, index| Geom::Vector3d.new [0,0].insert(index, len) }
    box_params = [ORIGIN, vectors]
    profile = [[0,0], [10,0], [10,20], [0,20]].map { |pos| Geom::Point3d.new pos }
    push_pull_vector = Geom::Vector3d.new 0,0,30
    xyz_tool = MockTool.new box_params, IDENTITY # gets nothing, returns box_params
    push_pull_tool = MockTool.new push_pull_vector, profile # gets rectangle, returns 3rd vector
    Parametric::Tools.set_default :xyz_tool, xyz_tool
    Parametric::Tools.set_default :push_pull_tool, push_pull_tool 
    subject = mock_block(nil, *box_params)
    Parametric::Tools::BoxTool.as_stage { |point, vectors| subject.call(point, vectors) }
    assert xyz_tool.used?
    assert push_pull_tool.used?
    assert subject.verify
  end
end
