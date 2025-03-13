require_relative 'drawing_factory'

module Parametric
	class PanelFactory < DrawingFactory
		required_params :length, :width, :thikness

		def draw
			container.add_group.tap do |panel| 
				panel.name = panel_name
				panel.entities.add_face(base_points).pushpull(-1 * thk)
			end
		end

		private

		def length
			param :length
		end

		def width
			param :width
		end

		def thikness
			param :thikness
		end

		def panel_name
			params.defined?(:name) ? param(:name) : 'Panel'
		end

		def base_points
			[
				ORIGIN,
				ORIGIN.offset(X_AXIS, length),
				ORIGIN.offset(X_AXIS, length).offset(Y_AXIS, width),
				ORIGIN.offset(Y_AXIS, width)
			]
		end
	end

	class PanelFactoryBuilder < Parametric::FactoryBuilder
		factory_class PanelFactory
	end
end
