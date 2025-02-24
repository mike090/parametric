require_relative 'factory'

module Parametric
	class TransformationFactory < Factory
		required_params :origin, :x_direction, :y_direction

		def initialize(**init_params)
			default = { origin: ORIGIN, x_direction: X_AXIS, y_direction: Y_AXIS }
			super **default.merge(init_params)
		end

		def do_build(environ)
			Geom::Transformation.new environ.origin, environ.x_direction, environ.y_direction
		end
	end
end