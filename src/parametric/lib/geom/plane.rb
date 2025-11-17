module Parametric
	module Geom
		class Plane < Array
			def initialize(*init_params)
				init_params = init_params.first if (init_params.length == 1) && init_params.first.is_a?(Array) 
				
				raw = Parametric::Geom::Plane.try_convert_to_plane(*init_params)
				return super raw if raw

				raise ArgumentError, "Invalid initial params #{init_params.map(&:class)} or points not planar"
			end

			def normal
				::Geom::Vector3d.new first(3)
			end

			def reverse
				Parametric::Geom::Plane.new(normal.reverse.to_a << -1 * last)
			end

			def internal_position(point)
				point.transform transformation_2d.inverse
			end

			def parallel?(plane)
				normal.parralel? plane.normal
			end

			# def intersect_with_plane(plane)
			# 	return ::Geom.intersect_plane_plane(self, plane) if Parametric::Geom::Plane.try_convert_to_plane(*plane)

			# 	return unless line_or_plane.is_a?(Array)

			# 	return ::Geom.intersect_line_plane(line_or_plane, self)
			# end

			def intersect_line(line)
				::Geom.intersect_line_plane(line, self)
			end

			def inspect
				"Plane(#{super})"
			end

			private

			def transformation_2d
				::Geom::Transformation.new(ORIGIN.project_to_plane(self), normal)
			end

			def self.try_convert_to_plane(*params)

				# from point and plane normal
				if params.length == 2 && ::Geom::Vector3d === params.last 
					point, vector = params
					vector_from_projection = ORIGIN.project_to_plane(point, vector) - ORIGIN
					distance = if vector_from_projection.valid?
						vector_from_projection.samedirection?(vector) ? -1 * vector_from_projection.length : vector_from_projection.length
					else
						0.0
					end
					return ::Geom::Vector3d.new(vector).normalize.to_a << distance
				end

				#from raw plane data
				return params.map(&:to_f) if params.length == 4 && params.all?(Numeric) && ::Geom::Vector3d.new(params.first(3))&.length == 1

				#from points
				points_planar?(*params.map { |param| ::Geom::Point3d.new(param) })

				#from point and line
				#...
			end

			# Returns a plane if all points on plane. Otherwise returns nil
			#
			# @param points [Geom::Point3d]
			# @return [Array, nil] array, representing a plane or nil
			def self.points_planar?(*points)
				return if points.length < 3

				plane = ::Geom::fit_plane_to_points points
				return unless points[3..-1].all? { |point| point.on_plane? plane }

				plane
			end
		end
	end
end