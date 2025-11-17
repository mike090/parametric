require_relative 'flatten'

module Parametric
	module Geom
		class Box < Flatten
			
			# The new method used to create a new box
			# @param [Geom::Transformation] - position used to set box position
			# @param [Geom::Vector3d] v1 one of the three vectors defining the box
			# @param [Geom::Vector3d] v2 one of the three vectors defining the box
			# @param [Geom::Vector3d] v3 one of the three vectors defining the box
			# @param [Boolean] normalize - sets box vertices[0] to position.orgin,
			# edges[0] along position.x_axis, adres[3] along position.y_axis
			def initialize(v1, v2, v3, position = IDENTITY,  normalize = true)
				base = [
					ORIGIN, 
					ORIGIN + v1,
					ORIGIN + v1 + v2,
					ORIGIN + v2
				]
				base.map! { |point| point.transform position }
				super base, v3.transform(position)
			end
		end
	end
end