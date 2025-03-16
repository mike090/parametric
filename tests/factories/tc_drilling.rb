require 'testup/testcase'
require_relative '../../src/parametric/factories/drilling'

class TC_Drilling < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end
	
	def test_build_drilling
		factory = Parametric::Drilling.new
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
		factory = Parametric::Drilling.new
		self._test_entity = factory.build(
			diameter: 5.mm, 
			depth: 12.5.mm, 
			normal: Z_AXIS.reverse, 
			position: Geom::Transformation.new([2,1,0])
		)
		dict = Parametric::Drilling.dictonary_name
		assert_equal 'drilling', _test_entity.get_attribute(dict, 'type')
		assert_equal 5.0, _test_entity.get_attribute(dict, 'diameter')
		assert_equal 12.5, _test_entity.get_attribute(dict, 'depth')
	end

	def test_build_with_drilling_scheme
		factory = Parametric::Drilling.new
		self._test_entity = factory.build scheme: '5x11,5'
		assert_equal 'Drilling D5x11.5', _test_entity.name
		dict = Parametric::Drilling.dictonary_name
		assert_equal 5.0, _test_entity.get_attribute(dict, 'diameter')
		assert_equal 11.5, _test_entity.get_attribute(dict, 'depth')
	end

	def test_init_with_drilling_scheme
		factory = Parametric::Drilling.new scheme: '5x11,5'
		self._test_entity = factory.build
		assert_equal 'Drilling D5x11.5', _test_entity.name
	end

	def test_drilling_scheme
		factory = Parametric::Drilling.new scheme: '5x11'
		factory.define_singleton_method(:do_build) { { d: diameter.to_mm, depth: depth.to_mm } }
		assert_equal({ d: 5, depth: 11 }, factory.build)
		assert_equal({ d: 5.2, depth: 11.5 }, factory.build(scheme: 'D5,2*11.5'))
		assert_equal({ d: 35, depth: 12.5 }, factory.build(scheme: 'd35*12.5'))
	end
end