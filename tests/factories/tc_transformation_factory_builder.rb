require 'testup/testcase'
require_relative '../../src/parametric/factories/transformation_factory'

class TC_TransformationFactoryBuilder < TestUp::TestCase
	def test_build_factory
		factory = Parametric::TransformationFactoryBuilder.build_factory(origin: [16.mm,0,0]) do
			x_axis_directed_along Z_AXIS
			y_direction Y_AXIS.reverse
		end
		trn = factory.build
		assert_instance_of Geom::Transformation, trn
		assert_equal [16.mm,0,0], trn.origin.to_a
		assert_equal Z_AXIS, trn.xaxis
		assert_equal X_AXIS, trn.zaxis
	end
end