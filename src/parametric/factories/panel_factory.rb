require_relative 'drawing_factory'

module Parametric
	class PanelFactory < DrawingFactory
		required_params :length, :width, :thikness

		def draw(environ)
			len = environ.length
			wd = environ.width
			thk = environ.thikness

			panel = environ.container.add_group
			panel.name = environ.name if environ.defined? :name
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
