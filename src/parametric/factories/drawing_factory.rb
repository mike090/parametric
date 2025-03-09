require_relative '../lib/factory'

module Parametric
	class DrawingFactory < Factory
		required_params :container

		def initialize(**init_params)
			super **{ container: Sketchup.active_model.entities }.merge(init_params)
		end

		def do_build(environ)
			entity = draw(environ)
			entity.transform!(params.get :position, environ) if entity.respond_to?(:transform!) &&
																														params.defined?(:position)
		end

		def draw(environ)
			raise 'Abstract method called'
		end
	end
end
