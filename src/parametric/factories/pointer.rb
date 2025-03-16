require_relative 'drawing_factory'

module Parametric
	class Pointer < DrawingFactory

		class << self
			attr_accessor :layer_name, :size
		end

		self.layer_name = '_pointers'
		self.size = 2.mm

		required_params :point, :normal, :v1
		define_param_readers :point, :normal

		def draw
			container.add_group.tap do |pointer|
				4.times do |i|
					vector = v1.transform Geom::Transformation.rotation(point, normal, i * 90.degrees)
					pointer.entities.add_cline point, point.offset(vector)
				end
				pointer.name = 'pointer'
				pointer.layer = Sketchup.active_model.layers.add(Parametric::Pointer.layer_name)
			end
		end

		private

		def v1
			@v1 ||= Vector3d.new(param :v1).tap { |vector| vector.length = Parametric::Pointer.size / 2 }
		end
	end
end