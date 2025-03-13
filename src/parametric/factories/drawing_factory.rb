require_relative '../lib/factory'

module Parametric
	class DrawingFactory < Factory
		required_params :container

		def initialize(**init_params)
			super **{ container: Sketchup.active_model.entities }.merge(init_params)
		end

		def do_build
			entity = draw
			entity.transform!(param :position) if entity.respond_to?(:transform!) &&
																														params.defined?(:position)
			entity
		end

		def draw
			raise 'Abstract method called'
		end

		private

		def clear!
			@container = nil
		end

		def container
			@container ||= param :container
		end
	end
end
