require 'testup/testcase'
require_relative '../../src/parametric/factories/pointer_factory'

class TC_PointerFactory < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end

  def test_draw_pointer
  	point = [1,1,0]
  	normal = Z_AXIS
  	v1 = Y_AXIS
    self._test_entity = Parametric::PointerFactory.new.build(point:, normal:, v1:)
    assert_instance_of Sketchup::Group, _test_entity
    assert _test_entity.entities.all? Sketchup::Edge
    assert_equal 4, _test_entity.entities.count
  end
 end