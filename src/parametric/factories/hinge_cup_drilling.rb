require_relative 'drawing_factory'
require_relative 'drilling'

module Parametric
	class HingeCupDrilling < DrawingFactory

		DEFAULT_CUP_DRILL_SCHEME = '35x13'
		DEFAULT_FIXING_DRILL_SCHEME = '3x1'

		required_params :hinge_map, :bore_distance
		define_param_readers :hinge_map, :bore_distance, :cup_drilling_params, :fixing_drilling_params

		def initialize(**init_params)
			default = {
				cup_drilling_params: { scheme: DEFAULT_CUP_DRILL_SCHEME },
				fixing_drilling_params: { scheme: DEFAULT_FIXING_DRILL_SCHEME }
			}
			super **default.merge(init_params)
		end

		def draw
			drilling_map = Mapper.new.build map: hinge_map, bore: bore_distance

			container.add_group.tap do |cup_drilling|
				drill.build **cup_drilling_params, position: drilling_map.cup_center, container: cup_drilling.entities
				drilling_map.cup_fixes.each do |pos|
					drill.build **fixing_drilling_params, position: pos, container: cup_drilling.entities
				end
				cup_drilling.name = 'Hinge cup drilling'
				cup_drilling.set_attribute 'Parametric', 'type', 'drilling_group'
			end			
		end

		private

		def parse_params(**params)
			params[:bore_distance] = params.delete :bore if params[:bore]
			super
		end

		def drill
			@drill ||= Parametric::Drilling.new
		end

		class Mapper < Factory
			required_params :bore_distance, :interfixes_distance, :cup_fixes_offset
			define_param_readers :bore_distance, :interfixes_distance, :cup_fixes_offset

			def do_build
				hinge_cup_center = Geom::Point3d.new(0, bore_distance + (35.0 / 2).mm)
				Parametric::Maps::HingeCup.new(
					hinge_cup_center,
					hinge_cup_center.offset([(-interfixes_distance / 2),cup_fixes_offset]),
					hinge_cup_center.offset([(interfixes_distance / 2),cup_fixes_offset])
				)
			end

			private

			def parse_params(**params)
				params[:bore_distance] = params.delete :bore if params[:bore]
				hinge_map = params[:map]
				params.merge!try_parse_map(hinge_map) if hinge_map
				super
			end

			def try_parse_map(map)
				raise "invalid hinge cup map. Expected string but #{map} has been received" unless String === map

				values = (map.scan /^(\d+)[x|*|х]([0-9]*[.,]?[0-9]+)/).first
				if values && values.length == 2
					values.map! { |value| value.sub(',', '.').to_f.mm }
					[:interfixes_distance, :cup_fixes_offset].zip(values).to_h
				else
					raise "invalid hinge cup map #{map}"
				end
			end
		end
	end
end
