require 'testup/testcase'
require_relative '../../src/parametric/factories/drawing_factory'

class TC_DrawingFactory < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
   _test_entity.erase! if _test_entity
  end

	def test_transformation_applies
		factory_class = Class.new Parametric::DrawingFactory
		factory_class.define_method(:draw) do
			_test_entity = param(:container).add_group.tap do |group|
				group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
			end
		end
		self._test_entity = factory_class.new.build position: Geom::Transformation.new([1,0,0])
		assert_equal [1,0,0], self._test_entity.transformation.origin.to_a
	end

	def test_poisition_as_point
		point = Geom::Point3d.new(1, 2, 3)
		 self._test_entity = Class.new(Parametric::DrawingFactory) do 
			define_method(:draw) do
				param(:container).add_group.tap do |group|
					group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
				end
			end
		end.new(position: point).build
		assert_equal point, _test_entity.transformation.origin
	end

	def test_poisition_as_vector
		vector = Geom::Vector3d.new(1, 2, 3)
		 self._test_entity = Class.new(Parametric::DrawingFactory) do 
			define_method(:draw) do
				param(:container).add_group.tap do |group|
					group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
				end
			end
		end.new(position: vector).build
		assert_equal [1,2,3], _test_entity.transformation.origin.to_a
	end

	def test_poisition_as_array
		value = [1, 2, 3]
		 self._test_entity = Class.new(Parametric::DrawingFactory) do 
			define_method(:draw) do
				param(:container).add_group.tap do |group|
					group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
				end
			end
		end.new(position: value).build
		assert_equal [1,2,3], _test_entity.transformation.origin.to_a
	end

	def test_invalid_position_raises
		factory = Class.new(Parametric::DrawingFactory) do 
			define_method(:draw) do
				param(:container).add_group.tap do |group|
					group.entities.add_face([0,0,0], [1,0,0], [1,1,0], [0,1,0]).pushpull(-1)
				end
			end
		end.new
		assert_raises { factory.build position: 5 }
		assert_raises { factory.build position: 'fake'}
	end
end