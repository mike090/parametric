require 'testup/testcase'
require_relative '../../src/parametric/factories/transformation_factory'

class TC_TransformationFactory < TestUp::TestCase
	attr_reader :subject

	def setup
		@subject = Parametric::TransformationFactory.new	
	end

	def test_returned_transformation
		tr = subject.build origin: [1,2,3], x_direction: Y_AXIS, y_direction: Z_AXIS
		assert_instance_of Geom::Transformation, tr
		assert_equal [1,2,3], tr.origin.to_a
		assert_equal Y_AXIS, tr.xaxis
		assert_equal X_AXIS, tr.zaxis
	end

	def test_default_result
		tr = subject.build
		assert_equal [0,0,0], tr.origin.to_a
		assert_equal X_AXIS, tr.xaxis
		assert_equal Y_AXIS, tr.yaxis
		assert_equal Z_AXIS, tr.zaxis
	end
end