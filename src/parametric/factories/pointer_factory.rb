require_relative 'drawing_factory'

module Parametric
	class PointerFactory < DrawingFactory

		class << self
			attr_accessor :layer_name, :size
		end

		self.layer_name = '_pointers'
		self.size = 1.mm

		required_params :point, :normal, :v1

		def draw
			container.add_group.tap do |pointer|
				pointer.name = 'pointer'
				4.times do |i|
					vector = i == 0 ? v1 : v1.transform Geom::Transformation.rotation(point, normal, i * 90.degrees)
					pointer.entities.add_line point, point.offset(vector)
				end
				pointer.layer = Sketchup.active_model.layers.add(Parametric::PointerFactory.layer_name)
			end
		end

		private

		def point
			@point ||= param :point
		end

		def normal
			@normal ||= param :normal
		end

		def v1
			@v1 ||= Vector3d.new param(:v1).tap { |vector| vector.length = Parametric::PointerFactory.size / 2 }
		end
	end
end