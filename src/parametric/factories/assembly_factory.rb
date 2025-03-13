require_relative 'drawing_factory'

module Parametric
	class AssemblyFactory < DrawingFactory

		def draw
			container = param :container
			container.add_group.tap do |group|
				entity_builders.each { |factory| factory.build @environ, container: group.entities }
			end
		end

		def use(drawing_factory)
			entity_builders << drawing_factory
		end

		private

		def entity_builders
			@entity_builders ||= []
		end
	end
end