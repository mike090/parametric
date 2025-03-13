require 'testup/testcase'
require_relative '../../src/parametric/factories/drawing_factory'

class TC_DrawingFactory < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end

	def test_transformation_applies
		factory_class = Class.new Parametric::DrawingFactory
		factory_class.define_method :draw do
			group = param(:container).add_group.tap do |group|
			group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
			group
		end
		self._test_entity = factory_class.new.build position: Geom::Transformation.new([1,0,0])
		assert_equal [1,0,0], self._test_entity.transformation.origin.to_a
	end
end