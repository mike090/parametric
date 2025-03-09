require 'testup/testcase'
require_relative '../../src/parametric/factories/drawing_factory'

class TC_DrawingFactory < TestUp::TestCase
	def test_transformation_applies
		factory_class = Class.new Parametric::DrawingFactory
		factory_class.define_method :draw do |_env|
			group = params.get(:container).add_group
			group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
			group
		end
		group = factory_class.new.build position: Geom::Transformation.new([1,0,0])
		assert_equal [1,0,0], group.transformation.origin.to_a
	end
end