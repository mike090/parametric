require_relative '../lib/factory'

module Parametric
	class DrawingFactory < Factory
		required_params :container

		define_param_readers :container

		def initialize(**init_params)
			super **{ container: Sketchup.active_model.entities }.merge(init_params)
		end

		def do_build
			pos = position if params.defined?(:position) # this prevent geometry generation if position raises
			draw.tap do |entity|
				entity.transform!(pos) if pos && entity.respond_to?(:transform!)
			end
		end

		def position
			pos_value = param :position
			return pos_value if pos_value.instance_of? Geom::Transformation

			raise "can't convert #{value.class} into Geom::Transformation" unless [Geom::Point3d, Geom::Vector3d, Array].include? pos_value.class

			begin
				Geom::Transformation.new pos_value
			rescue TypeError => e
				raise "can't convert #{value.class} into Geom::Transformation"
			end
		end

		def draw
			raise 'Abstract method called'
		end
	end
end
