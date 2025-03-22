require_relative 'drawing_factory'
require_relative 'hinge_cup_mapper'

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
			drilling_map = Parametric::HingeCupMapper.new.build map: hinge_map, bore: bore_distance

			container.add_group.tap do |cup_drilling|
				drill = Parametric::Drilling.new container: cup_drilling.entities
				drill.build **cup_drilling_params, position: drilling_map.cup_center
				drilling_map.cup_fixes.each do |pos|
					drill.build **fixing_drilling_params, position: pos
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
	end
end
