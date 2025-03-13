require 'testup/testcase'
require_relative '../../src/parametric/factories/pointer_factory'

class TC_PointerFactory < TestUp::TestCase
	attr_accessor :_test_geometry

	def teardown
    _test_geometry.erase! if _test_geometry
  end

  def test_draw_pointer
  	point = [1,1,0]
  	normal = Z_AXIS
  	v1 = Y_AXIS
    _test_geometry = Parametric::PointerFactory.new.build(point:, normal:, v1:)
    assert_instance_of Sketchup::Group, _test_geometry
    assert _test_geometry.entities.all? Sketchup::Edge
    assert_equal 4, _test_geometry.entities.count
  end
 end