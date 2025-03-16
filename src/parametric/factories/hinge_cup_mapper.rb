require_relative '../lib/factory'
require_relative '../models/maps/hinge_cup'

module Parametric
	class HingeCupMapper < Factory
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