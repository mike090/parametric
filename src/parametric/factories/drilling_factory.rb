require_relative 'drawing_factory'
require_relative 'pointer_factory'

module Parametric
	class DrillingFactory < DrawingFactory

		class << self
			attr_accessor :dictonary_name, :layer_name
		end

		self.dictonary_name = 'Machining'
		self.layer_name = '_machining'

		required_params :diameter, :depth, :normal

		def draw
			container.add_group.tap do |group|
				curve = group.entities.add_circle(ORIGIN, normal, diameter/2)
				group.name = "D#{fvalue_format diameter}x#{fvalue_format depth}"
				group.layer = Sketchup.active_model.layers.add(Parametric::DrillingFactory.layer_name)
				set_attributes group
				draw_pointer(group.entities, curve)
			end
		end

		private

		def fvalue_format(value)
			value.to_mm.round(1) % 1 > 0 ? value.to_mm.round(1) : value.to_mm.round
		end

		def draw_pointer(container, curve)
			Parametric::PointerFactory.new.build(
				container:,
				point: ORIGIN, 
				normal: param(:normal),
				v1: Vector3d.new(curve.first.curve.xaxis)
			)
		end

		def set_attributes(group)
			group.set_attribute dict, 'type', 'drilling'
			group.set_attribute dict, 'diameter', diameter.to_mm.round(1)
			group.set_attribute dict, 'depth', depth.to_mm.round(1)
		end

		def diameter
			param :diameter
		end

		def depth
			param :depth
		end

		def normal
			param :normal
		end

		def dict
			Parametric::DrillingFactory.dictonary_name
		end
	end
end