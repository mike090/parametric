require 'testup/testcase'
require_relative '../../src/parametric/factories/drilling_factory'

class TC_DrillingFactory < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end
	
	def test_build_drilling
		factory = Parametric::DrillingFactory.new
		self._test_entity = factory.build(
			diameter: 8.mm, 
			depth: 12.5.mm, 
			normal: Z_AXIS.reverse, 
			position: Geom::Transformation.new([1,1,0])
		) 
		assert_instance_of Sketchup::Group, _test_entity
		assert_equal 'Drilling D8x12.5', _test_entity.name
		assert_instance_of Sketchup::ArcCurve, _test_entity.entities.grep(Sketchup::Edge).first.curve
		assert_equal Z_AXIS.reverse, _test_entity.entities.first.curve.normal
		assert_equal [1,1,0], _test_entity.transformation.origin.to_a
	end

	def test_attributes
		factory = Parametric::DrillingFactory.new
		self._test_entity = factory.build(
			diameter: 5.mm, 
			depth: 12.5.mm, 
			normal: Z_AXIS.reverse, 
			position: Geom::Transformation.new([2,1,0])
		)
		dict = Parametric::DrillingFactory.dictonary_name
		assert_equal 'drilling', _test_entity.get_attribute(dict, 'type')
		assert_equal 5.0, _test_entity.get_attribute(dict, 'diameter')
		assert_equal 12.5, _test_entity.get_attribute(dict, 'depth')
	end
end