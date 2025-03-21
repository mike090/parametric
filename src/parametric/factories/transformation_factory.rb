require_relative '../lib/factory'

module Parametric
	class TransformationFactory < Factory
		required_params :origin, :x_direction, :y_direction
		define_param_readers :origin, :x_direction, :y_direction

		def initialize(**init_params)
			default = { origin: ORIGIN, x_direction: X_AXIS, y_direction: Y_AXIS }
			super **default.merge(init_params)
		end

		def do_build
			Geom::Transformation.new origin, x_direction, y_direction
		end
	end

	class TransformationFactoryBuilder < Parametric::FactoryBuilder
		factory_class TransformationFactory

		class << self
			private

			def x_axis_directed_along(value = nil, &block)
				@factory.set_param :x_direction, value, &block
			end

			def y_axis_directed_along(value = nil, &block)
				@factory.set_param :y_direction, value, &block
			end
		end
	end

	Parametric.register_builder :position, TransformationFactoryBuilder
end