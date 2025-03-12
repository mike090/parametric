require_relative 'drawing_factory'

module Parametric
	class PanelFactory < DrawingFactory
		required_params :length, :width, :thikness

		def draw
			len = param :length
			wd = param :width
			thk = param :thikness

			panel = param(:container).add_group
			panel.name = param :name if params.defined? :name
			panel.entities.add_face(
				[0,0,0],
				[len,0,0],
				[len,wd,0],
				[0,wd,0]
			).pushpull(-1 * thk)
			panel
		end
	end

	class PanelFactoryBuilder < Parametric::FactoryBuilder
		factory_class PanelFactory
	end
end
