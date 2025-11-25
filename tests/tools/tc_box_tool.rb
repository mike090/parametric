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
    assert x2_tool.as_stage(2) { |params| block.call(*params) }
    assert x2_tool.used?
    assert block.verify
  end

  def test_as_stage
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


#   def test_to_a
#     subject = Parametric::BoxTool::BoxModel.new
#     subject.first_corner = ORIGIN
#     assert_equal([ORIGIN], subject.to_a)
#     v1, v2, v3 = [[0,1,0], [1,0,0], [0,0,1]].map { |vals| Geom::Vector3d.new vals }
#     subject.dx = v1
#     assert_equal([ORIGIN,v1], subject.to_a)
#     subject.dz = v3
#     assert_equal([ORIGIN,v1,v3], subject.to_a)
#     subject.dy = v2
#     assert_equal([ORIGIN,v1,v2,v3], subject.to_a)
#   end

#   def test_base
#     subject = Parametric::BoxTool::BoxModel.new
#     assert_equal(nil, subject.base)
#     subject.first_corner = Geom::Point3d.new 1,1,0
#     subject.dx = Geom::Vector3d.new(-1, 0, 0)
#     subject.dy = Geom::Vector3d.new(0, 1, 0)
#     assert_equal([[1,1,0], [0,1,0], [0,2,0], [1,2,0]].map { |p| Geom::Point3d.new p }, subject.base)
#   end
# end

# class TC_BoxTool < TestUp::TestCase
#   def test_VCB
#     subject = Parametric::BoxTool.new
#     model = subject.model
#     refute subject.enableVCB? # disabled unless first corner
#     model.first_corner = ORIGIN
#     assert subject.enableVCB? # enabled when first corner
#     model.dx = 1
#     refute subject.enableVCB? # disabled with invalid model state
#     model.dy = 1
#     assert subject.enableVCB?
#   end

#   def test_user_text
#     subject = Parametric::BoxTool.new
#     model = subject.model
#     model.first_corner = 0
#     subject.onUserText('100;200;300', Sketchup.active_model.active_view)
#     vectors = [['100'.to_l,0], [0,'200'.to_l], [0,0,'300'.to_l]].map { |value| Geom::Vector3d.new value }  
#     assert_equal [0] + vectors, subject.model.to_a
#     subject = Parametric::BoxTool.new
#     model = subject.model
#     model.first_corner = 0
#     subject.onUserText('100;200', Sketchup.active_model.active_view)
#     vectors = [['100'.to_l,0], [0,'200'.to_l]].map { |value| Geom::Vector3d.new value }
#     assert_equal [0] + vectors, subject.model.to_a
#     subject.onUserText('50', Sketchup.active_model.active_view)
#     assert_equal [0] + vectors + [Geom::Vector3d.new(0,0,50.mm)], subject.model.to_a
#   end

#   def test_integration
#     view = Sketchup.active_model.active_view
#     points = [
#       Geom::Point3d.new(10, 5, 0),
#       Geom::Point3d.new(20, 25, 0),
#       Geom::Point3d.new(30, 30, 20)
#     ]
#     scr_pos = points.map { |p| view.screen_coords p }
#     subject = Parametric::BoxTool.new
#     model = subject.model
#     subject.onLButtonDown(nil, scr_pos[0].x, scr_pos[0].y, view)
#     assert model.first_corner
#     refute model.dx || model.dy || model.dz
#     subject.onLButtonDown(nil, scr_pos[1].x, scr_pos[1].y, view)
#     assert model.first_corner && model.dx && model.dy
#     refute model.dz
#     subject.onLButtonDown(nil, scr_pos[2].x, scr_pos[2].y, view)
#     assert model.first_corner && model.dx && model.dy && model.dz
#     assert_equal [Geom::Point3d] + [Geom::Vector3d] * 3, model.to_a.map(&:class)
#   end

#   def test_undo
#     view = Sketchup.active_model.active_view
#     subject = Parametric::BoxTool.new
#     model = subject.model
#     subject.onLButtonDown(nil, 10, 10, view)
#     assert model.first_corner
#     subject.onKeyUp(27,false, nil, view)
#     refute model.first_corner
#     subject.onLButtonDown(nil, 10, 10, view)
#     subject.onLButtonDown(nil, 20, 20, view)
#     subject.onLButtonDown(nil, 30, 30, view)
#     assert model.first_corner && model.dx && model.dy && model.dz
#     subject.onKeyUp(27,false, nil, view)
#     assert model.first_corner && model.dx && model.dy
#     refute model.dz
#     subject.onKeyUp(27,false, nil, view)
#     assert model.first_corner
#     refute model.dx || model.dy || model.dz
#     subject.onKeyUp(27,false, nil, view)
#     refute model.to_a.any?
#   end

#   def test_draw
#     subject = Parametric::BoxTool.new
#     model = subject.model
#     view = Sketchup.active_model.active_view
#     subject.onLButtonDown(nil, 10, 10, view)
#     subject.onMouseMove(nil, 20, 20, view)
#     assert_instance_of Sketchup::View, subject.draw(view)
#     subject.onUserText('20;30', view)
#     subject.onMouseMove(nil, 20, 30, view)
#     assert model.dx && model.dy
#     assert_instance_of Sketchup::View, subject.draw(view) 
#   end
end