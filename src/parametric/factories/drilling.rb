require_relative 'drawing_factory'
require_relative 'pointer'

module Parametric
	class Drilling < DrawingFactory

		class << self
			attr_accessor :dictonary_name, :layer_name
		end

		self.dictonary_name = 'Machining'
		self.layer_name = '_machining'

		required_params :diameter, :depth, :normal
		define_param_readers :diameter, :depth, :normal

		def initialize(**init_params)
			default = { normal: Z_AXIS }
			super **default.merge(init_params)
		end

		def draw
			container.add_group.tap do |drilling|
				curve = drilling.entities.add_circle(ORIGIN, normal, diameter/2)
				drilling.name = format_name
				drilling.layer = Sketchup.active_model.layers.add(Parametric::Drilling.layer_name)
				set_attributes(drilling)
				draw_pointer(drilling.entities, curve)
			end
		end

		private

		def format_name
			"Drilling D#{fvalue_format diameter}x#{fvalue_format depth}"
		end

		def fvalue_format(value)
			value.to_mm.round(1) % 1 > 0 ? value.to_mm.round(1) : value.to_mm.round
		end

		def draw_pointer(container, curve)
			Parametric::Pointer.new.build(
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

		def dict
			Parametric::Drilling.dictonary_name
		end

		def parse_params(**params)
			scheme = params[:scheme]
			params.merge! parse_scheme(scheme) if scheme
			params 
		end

		def parse_scheme(scheme)
			raise "invalid drilling scheme. It mast be string like 'D5x11'" unless String === scheme

			values = (scheme.scan /^[Dd]?(\d+[.,]?\d?)[x|*|х](\d+[.,]?\d?)/).first
			if values && values.length == 2
				values.map! { |value| value.sub(',', '.').to_f.mm }
				[:diameter, :depth].zip(values).to_h
			else
				raise "invalid drilling scheme #{scheme}"
			end
		end
	end
end