require_relative '../lib/factory'

module Parametric
	class DrawingFactory < Factory
		required_params :container

		define_param_readers :container

		def initialize(**init_params)
			super **{ container: Sketchup.active_model.entities }.merge(init_params)
		end

		def do_build
			draw.tap do |entity|
				entity.transform!(param :position) if entity.respond_to?(:transform!) &&
																														params.defined?(:position)
			end
		end

		def draw
			raise 'Abstract method called'
		end
	end
end
