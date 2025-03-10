require 'testup/testcase'
require_relative '../../src/parametric/factories/drawing_factory'

class TC_DrawingFactory < TestUp::TestCase
	attr_accessor :temp_geometry

	def teardown
    temp_geometry.erase! if temp_geometry
  end

	def test_transformation_applies
		factory_class = Class.new Parametric::DrawingFactory
		factory_class.define_method :draw do |_env|
			group = params.get(:container).add_group
			group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
			group
		end
		self.temp_geometry = factory_class.new.build position: Geom::Transformation.new([1,0,0])
		assert_equal [1,0,0], self.temp_geometry.transformation.origin.to_a
	end
end